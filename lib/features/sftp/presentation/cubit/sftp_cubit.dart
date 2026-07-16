import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> upload() async {
    if (_denied()) return;
    final session = _session;
    if (session == null || _transferBusy()) return;
    final picked = (await FilePicker.platform.pickFiles(
      dialogTitle: "Upload to ${state.path}",
    ))?.files.single;
    final localPath = picked?.path;
    if (picked == null || localPath == null || isClosed) return;

    _startTransfer(picked.name, isUpload: true, total: picked.size);
    try {
      await session.upload(
        localPath,
        RemotePath.join(state.path, picked.name),
        onProgress: (bytes) => _tick(bytes, picked.size),
      );
      if (isClosed) return;
      emit(state.copyWith(clearTransfer: true));
      await refresh();
    } on SshConnectionException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(clearTransfer: true, errorMessage: e.message));
      }
    }
  }

  Future<void> download(RemoteFile file) async {
    final session = _session;
    if (session == null || _transferBusy()) return;
    if (Platform.isAndroid || Platform.isIOS) {
      await _downloadMobile(session, file);
    } else {
      await _downloadDesktop(session, file);
    }
  }

  // Desktop's save dialog returns a real path, so the download streams
  // straight to it.
  Future<void> _downloadDesktop(SftpSession session, RemoteFile file) async {
    final localPath = await FilePicker.platform.saveFile(
      dialogTitle: "Save ${file.name}",
      fileName: file.name,
    );
    if (localPath == null || isClosed) return;

    _startTransfer(file.name, isUpload: false, total: file.size);
    try {
      await session.download(
        file,
        localPath,
        onProgress: (bytes) => _tick(bytes, file.size),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            clearTransfer: true,
            noticeMessage: "Saved to $localPath",
          ),
        );
      }
    } on SshConnectionException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(clearTransfer: true, errorMessage: e.message));
      }
    }
  }

  // Android's save dialog returns a content:// URI, which cannot be streamed
  // into, so the download goes to a temp file and the dialog opens afterward.
  Future<void> _downloadMobile(SftpSession session, RemoteFile file) async {
    final String tempPath;
    try {
      final dir = await getTemporaryDirectory();
      tempPath = "${dir.path}/${file.name}";
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: "Could not prepare the download."));
      }
      return;
    }

    _startTransfer(file.name, isUpload: false, total: file.size);
    try {
      await session.download(
        file,
        tempPath,
        onProgress: (bytes) => _tick(bytes, file.size),
      );
    } on SshConnectionException catch (e) {
      await _deleteQuietly(tempPath);
      if (!isClosed) {
        emit(state.copyWith(clearTransfer: true, errorMessage: e.message));
      }
      return;
    }
    if (isClosed) {
      await _deleteQuietly(tempPath);
      return;
    }

    try {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: "Save ${file.name}",
        fileName: file.name,
        bytes: await File(tempPath).readAsBytes(),
      );
      if (!isClosed) {
        // A null result is a dismissed dialog, not a saved file.
        emit(
          state.copyWith(
            clearTransfer: true,
            noticeMessage: saved == null ? null : "Saved ${file.name}",
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            clearTransfer: true,
            errorMessage: "Could not save the file.",
          ),
        );
      }
    } finally {
      await _deleteQuietly(tempPath);
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover temp file is harmless; the OS clears the cache directory.
    }
  }

  Future<void> _load(String path) async {
    final session = _session;
    if (session == null) return;
    try {
      final entries = await session.list(path);
      if (isClosed) return;
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
      if (isClosed) return;
      // The current listing stays on screen; only say why the move failed.
      if (state.status == SftpStatus.ready) {
        emit(state.copyWith(errorMessage: e.message, busy: false));
      } else {
        _fail(e.message);
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
