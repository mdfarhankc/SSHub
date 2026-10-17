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
    // A reconnect starts clean: nothing from the old session stays queued.
    _queue.clear();
    _resumers.clear();
    _connectionLost = false;
    _doneOk = 0;
    _doneFailed.clear();
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
    } catch (e, st) {
      appLog("Open SFTP session failed", e, st);
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

  Future<void> goToPath(String path) async {
    var target = path.trim();
    if (target.isEmpty) return;
    if (!target.startsWith('/')) target = '/$target';
    if (target.length > 1 && target.endsWith('/')) {
      target = target.substring(0, target.length - 1);
    }
    if (target != state.path) await _load(target);
  }

  // Opportunistic listing for the path-bar autocomplete. A folder that cannot
  // be read just yields no suggestions, so the failure is swallowed quietly
  // rather than logged on every keystroke into an inaccessible path.
  Future<List<RemoteFile>> listFolder(String path) async {
    final session = _session;
    if (session == null) return const [];
    try {
      final entries = await session.list(path);
      return [
        for (final e in entries)
          if (e.isDirectory) e,
      ];
    } catch (_) {
      return const [];
    }
  }

  void toggleHidden() {
    final value = !state.showHidden;
    emit(state.copyWith(showHidden: value));
    _settings.updateSftpShowHidden(value);
  }

  void toggleSearch() {
    final on = !state.searching;
    emit(state.copyWith(searching: on, searchQuery: on ? state.searchQuery : ''));
  }

  void setSearch(String query) => emit(state.copyWith(searchQuery: query));

  void enterSelection() => emit(state.copyWith(selecting: true));

  void exitSelection() =>
      emit(state.copyWith(selecting: false, selected: const <String>{}));

  void toggleSelected(String path) {
    final next = Set<String>.of(state.selected);
    if (!next.remove(path)) next.add(path);
    emit(state.copyWith(selected: next));
  }

  void selectAllVisible() => emit(
    state.copyWith(selected: {for (final e in state.visibleEntries) e.path}),
  );

  List<RemoteFile> _selectedEntries() => [
    for (final e in state.entries)
      if (state.selected.contains(e.path)) e,
  ];

  // Queues every selected item; the queue drains them in order and shows one
  // summary at the end.
  void downloadSelected() {
    final targets = _selectedEntries();
    exitSelection();
    for (final file in targets) {
      download(file);
    }
  }

  Future<void> deleteSelected() {
    final targets = _selectedEntries();
    exitSelection();
    return _mutate(() async {
      for (final file in targets) {
        await _session!.delete(file);
      }
    });
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

  Future<void> changePermissions(RemoteFile file, int permissions) =>
      _mutate(() => _session!.setPermissions(file.path, permissions));

  Future<({String owner, String group})> ownerNames(RemoteFile file) async {
    final session = _session;
    if (session == null) {
      return (
        owner: file.uid?.toString() ?? "unknown",
        group: file.gid?.toString() ?? "unknown",
      );
    }
    return session.ownerNames(file);
  }

  Future<({Map<int, String> users, Map<int, String> groups})>
  ownerOptions() async {
    final session = _session;
    if (session == null) {
      return (users: const <int, String>{}, groups: const <int, String>{});
    }
    return session.ownerOptions();
  }

  Future<void> changeOwner(RemoteFile file, {int? uid, int? gid}) =>
      _mutate(() => _session!.setOwner(file.path, uid: uid, gid: gid));

  Future<void> delete(RemoteFile file) => _mutate(() => _session!.delete(file));

  // [confirmOverwrite] is asked before replacing a file that already exists.
  Future<void> upload({
    Future<bool> Function(String name)? confirmOverwrite,
  }) async {
    if (_denied()) return;
    final session = _session;
    if (session == null) return;
    final picked = await FilePicker.pickFile(
      dialogTitle: "Upload to ${state.path}",
    );
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

    final size = await picked.length();
    if (isClosed) return;
    final id = _nextJobId++;
    final name = picked.name;
    var resumeFrom = 0;
    Future<void> run() async {
      final outcome = await _runTransfer(
        name,
        isUpload: true,
        total: size,
        pausable: true,
        action: () async {
          await session.upload(
            localPath,
            remotePath,
            resumeFrom: resumeFrom,
            onProgress: (bytes) => _tick(bytes, size),
          );
          return null;
        },
      );
      if (outcome == _Outcome.done && !isClosed) await refresh();
      if (outcome == _Outcome.paused) {
        resumeFrom = await session.fileSize(remotePath);
        _registerPaused(
          id,
          name,
          isUpload: true,
          done: resumeFrom,
          total: size,
          resume: run,
          discard: () async {
            try {
              await session.deletePath(remotePath);
            } catch (_) {}
          },
        );
      }
    }

    _enqueue(QueuedTransfer(id: id, name: name, isUpload: true), run);
  }

  // Uploads a whole local folder into the current directory.
  Future<void> uploadFolder({
    Future<bool> Function(String name)? confirmOverwrite,
  }) async {
    if (_denied()) return;
    final session = _session;
    if (session == null) return;
    final localPath = await FilePicker.getDirectoryPath(
      dialogTitle: "Upload folder to ${state.path}",
    );
    if (localPath == null || isClosed) return;

    final name = _localName(localPath);
    final remotePath = RemotePath.join(state.path, name);
    try {
      if (await session.exists(remotePath)) {
        final replace = await confirmOverwrite?.call(name) ?? false;
        if (!replace || isClosed) return;
      }
    } on SshConnectionException catch (e) {
      if (!isClosed) emit(state.copyWith(errorMessage: e.message));
      return;
    }

    // Size is unknown up front, so the bar shows an indeterminate transfer.
    _enqueue(
      QueuedTransfer(id: _nextJobId++, name: name, isUpload: true),
      () async {
        final outcome = await _runTransfer(
          name,
          isUpload: true,
          total: 0,
          action: () async {
            await session.uploadDirectory(
              localPath,
              state.path,
              onProgress: (bytes) => _tick(bytes, 0),
            );
            return "Uploaded to $remotePath";
          },
        );
        if (outcome == _Outcome.done && !isClosed) await refresh();
      },
    );
  }

  String _localName(String path) {
    final trimmed = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    return trimmed.substring(trimmed.lastIndexOf('/') + 1);
  }

  void cancelTransfer() {
    if (state.transfer == null) return;
    _session?.cancelTransfer();
  }

  // Pauses the active transfer if it can resume; the job registers itself as
  // paused once it stops.
  void pauseActiveTransfer() {
    if (state.transfer?.pausable != true) return;
    _session?.pauseTransfer();
  }

  void _registerPaused(
    int id,
    String name, {
    required bool isUpload,
    required int done,
    required int total,
    required Future<void> Function() resume,
    required Future<void> Function() discard,
  }) {
    if (isClosed) return;
    _resumers[id] = _PausedJob(resume, discard);
    emit(
      state.copyWith(
        paused: [
          ...state.paused,
          PausedTransfer(
            id: id,
            name: name,
            isUpload: isUpload,
            bytesDone: done,
            total: total,
          ),
        ],
      ),
    );
  }

  // Puts a paused transfer back on the queue to continue where it stopped.
  void resume(int id) {
    final job = _resumers.remove(id);
    if (job == null) return;
    final item = state.paused.where((p) => p.id == id).toList();
    if (item.isEmpty) return;
    emit(state.copyWith(paused: [for (final p in state.paused) if (p.id != id) p]));
    _queue.add(
      _QueuedJob(
        QueuedTransfer(id: id, name: item.first.name, isUpload: item.first.isUpload),
        job.resume,
      ),
    );
    _syncQueue();
    _drain();
  }

  // Drops a paused transfer and removes the partial it left behind.
  void cancelPaused(int id) {
    final job = _resumers.remove(id);
    emit(state.copyWith(paused: [for (final p in state.paused) if (p.id != id) p]));
    job?.discard();
  }

  Future<int> _localSize(String path) async {
    try {
      final file = File(path);
      return await file.exists() ? await file.length() : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _deleteLocalQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // Transfers run one at a time: new ones queue behind the active one and the
  // queue drains on its own. Results are collected and summarised once the
  // queue empties, rather than toasted per item.
  final List<_QueuedJob> _queue = [];
  int _nextJobId = 0;
  bool _draining = false;
  int _doneOk = 0;
  final _doneFailed = <String>[];
  String? _lastNotice;
  String? _lastError;
  // Set when a transfer fails because the connection dropped; stops the drain.
  bool _connectionLost = false;
  // Paused transfers, keyed by id, with the work to resume or discard them.
  final Map<int, _PausedJob> _resumers = {};

  void _enqueue(QueuedTransfer info, Future<void> Function() run) {
    _queue.add(_QueuedJob(info, run));
    _syncQueue();
    _drain();
  }

  void _syncQueue() {
    if (!isClosed) {
      emit(state.copyWith(queue: [for (final j in _queue) j.info]));
    }
  }

  // Runs queued jobs in order until the queue empties or the connection drops,
  // then shows one summary for the whole run.
  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (!isClosed && !_connectionLost && _queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        _syncQueue();
        await job.run();
      }
    } finally {
      _draining = false;
    }
    if (isClosed) return;
    final dropped = _connectionLost ? _queue.length : 0;
    if (dropped > 0) {
      _queue.clear();
      _syncQueue();
    }
    _emitQueueResult(dropped);
    _doneOk = 0;
    _doneFailed.clear();
    _lastNotice = null;
    _lastError = null;
    _connectionLost = false;
  }

  void _emitQueueResult(int dropped) {
    final failed = _doneFailed;
    final reported = _doneOk + failed.length;
    String? notice;
    String? error;
    if (reported <= 1 && dropped == 0) {
      // A lone transfer keeps its own detailed message.
      notice = _lastNotice;
      error = _lastError;
    } else {
      notice = _doneOk > 0
          ? "Finished $_doneOk ${_doneOk == 1 ? 'transfer' : 'transfers'}"
          : null;
      final parts = <String>[];
      if (failed.isNotEmpty) {
        parts.add(failed.length <= 3
            ? "failed: ${failed.join(', ')}"
            : "${failed.length} failed");
      }
      if (dropped > 0) parts.add("$dropped cancelled, connection lost");
      error = parts.isEmpty ? null : parts.join('; ');
    }
    emit(state.copyWith(noticeMessage: notice, errorMessage: error));
  }

  void removeQueued(int id) {
    _queue.removeWhere((j) => j.info.id == id);
    _syncQueue();
  }

  void clearQueue() {
    if (_queue.isEmpty) return;
    _queue.clear();
    _syncQueue();
  }

  // Runs one transfer, driving the active-transfer bar and recording the result
  // for the queue summary. Only the drain loop calls this. The active slot is
  // always freed, so a failure cannot strand the queue.
  Future<_Outcome> _runTransfer(
    String name, {
    required bool isUpload,
    required int total,
    bool pausable = false,
    required Future<String?> Function() action,
  }) async {
    _startTransfer(name, isUpload: isUpload, total: total, pausable: pausable);
    final startedAt = DateTime.now();
    String? notice;
    String? error;
    var outcome = _Outcome.failed;
    try {
      notice = await action();
      if (notice != null) {
        notice =
            "$notice in ${formatElapsed(DateTime.now().difference(startedAt))}";
      }
      outcome = _Outcome.done;
    } on SftpPaused {
      outcome = _Outcome.paused;
    } on SftpCancelled {
      outcome = _Outcome.stopped;
      notice = "Transfer stopped.";
    } on SshConnectionException catch (e) {
      error = e.message;
      _connectionLost = true;
    } catch (e) {
      appLog("Transfer failed", e);
      error = "The transfer could not be completed.";
    }
    if (!isClosed) {
      if (outcome == _Outcome.done) {
        _doneOk++;
      } else if (error != null) {
        _doneFailed.add(name);
      }
      // Stopped and paused transfers are not tallied as done or failed.
      _lastNotice = notice;
      _lastError = error;
      emit(state.copyWith(clearTransfer: true));
    }
    return outcome;
  }

  void download(RemoteFile file) {
    if (_session == null) return;
    final id = _nextJobId++;
    final info = QueuedTransfer(id: id, name: file.name, isUpload: false);
    if (file.isDirectory) {
      _enqueue(info, () async {
        final session = _session;
        if (session == null) return;
        await _downloadFolder(session, file);
      });
    } else {
      _enqueue(info, _fileDownloadJob(id, file));
    }
  }

  // A resumable single-file download. The local path is resolved once and
  // reused, so a resume appends to the same partial; resumeFrom tracks how far
  // it got.
  Future<void> Function() _fileDownloadJob(int id, RemoteFile file) {
    String? localPath;
    var resumeFrom = 0;
    Future<void> run() async {
      final session = _session;
      if (session == null) return;
      try {
        localPath ??= _unusedPath(await _downloadRoot(), file.name);
      } catch (_) {
        if (!isClosed) {
          emit(state.copyWith(errorMessage: "Could not prepare the download."));
        }
        return;
      }
      if (isClosed) return;
      final path = localPath!;
      final outcome = await _runTransfer(
        file.name,
        isUpload: false,
        total: file.size,
        pausable: true,
        action: () async {
          await session.download(
            file,
            path,
            resumeFrom: resumeFrom,
            onProgress: (bytes) => _tick(bytes, file.size),
          );
          return "Saved to $path";
        },
      );
      if (outcome == _Outcome.paused) {
        resumeFrom = await _localSize(path);
        _registerPaused(
          id,
          file.name,
          isUpload: false,
          done: resumeFrom,
          total: file.size,
          resume: run,
          discard: () => _deleteLocalQuietly(path),
        );
      }
    }

    return run;
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
    // A server-supplied name that is not a plain file name could escape the
    // download folder, so refuse it rather than write outside it.
    if (!RemotePath.isSafeLocalSegment(name)) {
      throw ArgumentError.value(name, 'name', 'unsafe download name');
    }
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
      // Moving to another folder drops the search; a refresh keeps it.
      final navigated = path != state.path;
      emit(
        state.copyWith(
          status: SftpStatus.ready,
          path: path,
          entries: entries,
          busy: false,
          clearMessages: true,
          searching: navigated ? false : null,
          searchQuery: navigated ? '' : null,
          selecting: navigated ? false : null,
          selected: navigated ? const <String>{} : null,
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
    bool pausable = false,
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
          pausable: pausable,
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

// A queued transfer: its display info plus the work that runs it.
class _QueuedJob {
  final QueuedTransfer info;
  final Future<void> Function() run;
  const _QueuedJob(this.info, this.run);
}

// How a single transfer attempt ended.
enum _Outcome { done, failed, stopped, paused }

// A paused transfer: the work to continue it, or to clean up its partial.
class _PausedJob {
  final Future<void> Function() resume;
  final Future<void> Function() discard;
  const _PausedJob(this.resume, this.discard);
}
