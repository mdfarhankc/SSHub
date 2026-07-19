import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sshub/core/format/elapsed.dart';
import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/domain/entities/remote_path.dart';
import 'package:sshub/features/sftp/domain/repositories/sftp_repository.dart';
import 'package:sshub/features/sftp/domain/usecases/open_sftp_session.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

part 'sftp_state.dart';

class SftpCubit extends Cubit<SftpState> {
  final OpenSftpSession _openSession;
  final SettingsCubit _settings;
  final SshServer server;
  SftpSession? _session;

  // isClosed only flips once close() has finished awaiting, so a session
  // landing mid-dispose would still look live.
  bool _disposing = false;

  // Progress fires per chunk, which is far more often than the UI can use, so
  // emits are limited to one every 100ms plus a final one at completion.
  static const _progressInterval = Duration(milliseconds: 100);
  DateTime _lastTick = DateTime.fromMillisecondsSinceEpoch(0);

  // The folder currently being listed, so a slower earlier request cannot
  // land after a newer one.
  String? _loadingPath;

  SftpCubit(this._openSession, this.server, this._settings)
    : super(_initial(_settings)) {
    connect();
  }

  // Every state that starts over has to carry the remembered view options
  // rather than fall back to the defaults.
  static SftpState _initial(SettingsCubit settings) => SftpState(
    showHidden: settings.state.settings.sftpShowHidden,
    gridView: settings.state.settings.sftpGridView,
    readOnly: settings.state.settings.sftpReadOnly,
  );

  // Lent to the file viewer so it reads over this channel. The viewer must not
  // close it; the browser owns it.
  SftpSession? get session => _session;

  Future<void> connect() async {
    emit(_initial(_settings));
    // Try Again comes back through here, and nothing else closes the previous
    // attempt's connection.
    await _session?.close();
    _session = null;
    try {
      final session = await _openSession(server);
      // The page can be popped while the connection is still in flight.
      if (_disposing || isClosed) {
        await session.close();
        return;
      }
      _session = session;
      await _load(await session.home());
    } on SshConnectionException catch (e) {
      _fail(e.message);
    } on StateError catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail("Could not open a file session.");
    }
  }

  Future<void> openDirectory(RemoteFile file) async {
    if (file.isDirectory) await _load(file.path);
  }

  Future<void> refresh() => _load(state.path);

  Future<void> goUp() async {
    if (!state.isRoot) await _load(RemotePath.parentOf(state.path));
  }

  void toggleHidden() {
    final value = !state.showHidden;
    emit(state.copyWith(showHidden: value));
    _settings.updateSftpShowHidden(value);
  }

  void toggleGridView() {
    final value = !state.gridView;
    emit(state.copyWith(gridView: value));
    _settings.updateSftpGridView(value);
  }

  void toggleReadOnly() {
    final value = !state.readOnly;
    emit(state.copyWith(readOnly: value));
    _settings.updateSftpReadOnly(value);
  }

  // One transfer slot: a second would overwrite the first and strand it.
  bool _transferBusy() {
    if (state.transfer == null) return false;
    emit(
      state.copyWith(errorMessage: "Wait for the current transfer to finish."),
    );
    return true;
  }

  // Every write passes through here, whichever path reaches it.
  bool _denied() {
    if (!state.readOnly) return false;
    emit(
      state.copyWith(
        errorMessage: "Read-only mode is on. Turn it off to make changes.",
      ),
    );
    return true;
  }

  void clearMessages() => emit(state.copyWith(clearMessages: true));

  Future<void> createDirectory(String name) =>
      _mutate(() => _session!.makeDirectory(RemotePath.join(state.path, name)));

  Future<void> rename(RemoteFile file, String newName) => _mutate(
    () => _session!.rename(file.path, RemotePath.join(state.path, newName)),
  );

  Future<void> delete(RemoteFile file) => _mutate(() => _session!.delete(file));

  // [confirmOverwrite] is asked before replacing a file that already exists.
  Future<void> upload({
    Future<bool> Function(String name)? confirmOverwrite,
  }) async {
    if (_denied()) return;
    final session = _session;
    if (session == null || _transferBusy()) return;
    final picked = (await FilePicker.platform.pickFiles(
      dialogTitle: "Upload to ${state.path}",
    ))?.files.single;
    final localPath = picked?.path;
    if (picked == null || localPath == null || isClosed) return;

    final remotePath = RemotePath.join(state.path, picked.name);
    try {
      if (await session.exists(remotePath)) {
        final replace = await confirmOverwrite?.call(picked.name) ?? false;
        if (!replace || isClosed) return;
      }
    } on SshConnectionException catch (e) {
      if (!isClosed) emit(state.copyWith(errorMessage: e.message));
      return;
    }

    final done = await _runTransfer(
      picked.name,
      isUpload: true,
      total: picked.size,
      action: () async {
        await session.upload(
          localPath,
          remotePath,
          onProgress: (bytes) => _tick(bytes, picked.size),
        );
        return null;
      },
    );
    if (done && !isClosed) await refresh();
  }

  void cancelTransfer() {
    if (state.transfer == null) return;
    _session?.cancelTransfer();
  }

  // The one transfer slot is freed here whatever the body does, so an
  // unexpected failure cannot leave the browser refusing every later transfer.
  Future<bool> _runTransfer(
    String name, {
    required bool isUpload,
    required int total,
    required Future<String?> Function() action,
  }) async {
    _startTransfer(name, isUpload: isUpload, total: total);
    final startedAt = DateTime.now();
    String? notice;
    String? error;
    var completed = false;
    try {
      notice = await action();
      if (notice != null) {
        notice =
            "$notice in ${formatElapsed(DateTime.now().difference(startedAt))}";
      }
      completed = true;
    } on SftpCancelled {
      notice = "Transfer stopped.";
    } on SshConnectionException catch (e) {
      error = e.message;
    } catch (e) {
      appLog("Transfer failed", e);
      error = "The transfer could not be completed.";
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          clearTransfer: true,
          noticeMessage: notice,
          errorMessage: error,
        ),
      );
    }
    return completed;
  }

  Future<void> download(RemoteFile file) async {
    final session = _session;
    if (session == null || _transferBusy()) return;
    if (file.isDirectory) {
      await _downloadFolder(session, file);
    } else {
      await _downloadFile(session, file);
    }
  }

  Future<void> _downloadFile(SftpSession session, RemoteFile file) async {
    final String localPath;
    try {
      localPath = _unusedPath(await _downloadRoot(), file.name);
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: "Could not prepare the download."));
      }
      return;
    }
    if (isClosed) return;

    await _runTransfer(
      file.name,
      isUpload: false,
      total: file.size,
      action: () async {
        await session.download(
          file,
          localPath,
          onProgress: (bytes) => _tick(bytes, file.size),
        );
        return "Saved to $localPath";
      },
    );
  }

  // Reads only, so read-only mode still allows it.
  Future<void> _downloadFolder(SftpSession session, RemoteFile folder) async {
    final String destination;
    try {
      destination = _unusedPath(await _downloadRoot(), folder.name);
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: "Could not prepare the download."));
      }
      return;
    }
    if (isClosed) return;

    // Size is unknown until the walk ends.
    await _runTransfer(
      folder.name,
      isUpload: false,
      total: 0,
      action: () async {
        final skipped = await session.downloadDirectory(
          folder,
          destination,
          onProgress: (files, bytes, name) => _tickFolder(files, bytes, name),
        );
        final skippedNote = skipped == 0 ? "" : ", $skipped skipped";
        return "Saved to $destination$skippedNote";
      },
    );
  }

  // The folder from settings, or the platform default if unset or gone.
  Future<String> _downloadRoot() async {
    final chosen = _settings.state.settings.downloadDirectory;
    if (chosen != null) {
      final directory = Directory(chosen);
      if (await directory.exists()) return chosen;
    }
    final fallback =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await fallback.create(recursive: true);
    return fallback.path;
  }

  void _tickFolder(int files, int bytes, String name) {
    if (isClosed || state.transfer == null) return;
    final now = DateTime.now();
    if (now.difference(_lastTick) < _progressInterval) return;
    _lastTick = now;
    emit(
      state.copyWith(
        transfer: state.transfer!.copyWith(
          transferred: bytes,
          detail: "$files files  ·  $name",
        ),
      ),
    );
  }

  // Nothing prompts for a location, so avoid replacing an earlier download.
  String _unusedPath(String directory, String name) {
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    final extension = dot <= 0 ? "" : name.substring(dot);
    var path = "$directory/$name";
    for (
      var n = 1;
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
      n++
    ) {
      path = "$directory/$stem ($n)$extension";
    }
    return path;
  }

  Future<void> _load(String path) async {
    final session = _session;
    if (session == null) return;
    _loadingPath = path;
    // Listing a folder is a round trip, so the bar has to say something is
    // happening. Connecting already has a screen of its own.
    if (state.status == SftpStatus.ready) emit(state.copyWith(busy: true));
    try {
      final entries = await session.list(path);
      // A newer folder was opened while this one was still loading.
      if (isClosed || _loadingPath != path) return;
      emit(
        state.copyWith(
          status: SftpStatus.ready,
          path: path,
          entries: entries,
          busy: false,
          clearMessages: true,
        ),
      );
    } on SshConnectionException catch (e) {
      if (isClosed || _loadingPath != path) return;
      // The current listing stays on screen; only say why the move failed.
      if (state.status == SftpStatus.ready) {
        emit(state.copyWith(errorMessage: e.message, busy: false));
      } else {
        _fail(e.message);
      }
    } catch (e) {
      appLog("Could not list $path", e);
      if (isClosed || _loadingPath != path) return;
      if (state.status == SftpStatus.ready) {
        emit(
          state.copyWith(
            errorMessage: "Could not open that folder.",
            busy: false,
          ),
        );
      } else {
        _fail("Could not open that folder.");
      }
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_denied() || _session == null) return;
    emit(state.copyWith(busy: true));
    try {
      await action();
      await refresh();
    } on SshConnectionException catch (e) {
      if (!isClosed) emit(state.copyWith(errorMessage: e.message, busy: false));
    }
  }

  void _startTransfer(
    String name, {
    required bool isUpload,
    required int total,
  }) {
    _lastTick = DateTime.fromMillisecondsSinceEpoch(0);
    emit(
      state.copyWith(
        transfer: SftpTransfer(
          name: name,
          isUpload: isUpload,
          transferred: 0,
          total: total,
          startedAt: DateTime.now(),
        ),
      ),
    );
  }

  void _tick(int bytes, int total) {
    if (isClosed || state.transfer == null) return;
    final now = DateTime.now();
    final finished = total > 0 && bytes >= total;
    if (!finished && now.difference(_lastTick) < _progressInterval) return;
    _lastTick = now;
    emit(
      state.copyWith(transfer: state.transfer!.copyWith(transferred: bytes)),
    );
  }

  void _fail(String message) {
    if (isClosed) return;
    emit(
      _initial(
        _settings,
      ).copyWith(status: SftpStatus.failure, errorMessage: message),
    );
  }

  @override
  Future<void> close() async {
    _disposing = true;
    await _session?.close();
    return super.close();
  }
}
