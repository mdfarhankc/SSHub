import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/domain/entities/remote_path.dart';
import 'package:sshub/features/sftp/domain/repositories/sftp_repository.dart';
import 'package:sshub/features/ssh/data/datasources/ssh_client_factory.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

class SftpRepositoryImpl implements SftpRepository {
  final SshClientFactory _clients;
  const SftpRepositoryImpl(this._clients);

  @override
  Future<SftpSession> connect(
    SshServer server, {
    String? password,
    String? privateKey,
    String? keyPassphrase,
  }) async {
    // A dedicated connection rather than a channel on a terminal tab: file
    // browsing must not depend on a shell being open, or die when it exits.
    final client = await _clients.authenticated(
      server,
      password: password,
      privateKey: privateKey,
      keyPassphrase: keyPassphrase,
    );
    try {
      final sftp = await client.sftp();
      return _DartSftpSession(client, sftp);
    } catch (e, st) {
      appLog("SFTP session build failed", e, st);
      // The client owns a socket and a keepalive timer, and the session that
      // would have closed them was never built.
      client.close();
      rethrow;
    }
  }
}

class _DartSftpSession implements SftpSession {
  final SSHClient _client;
  final SftpClient _sftp;

  _DartSftpSession(this._client, this._sftp);

  // Checked at every chunk and every entry, so a stop lands quickly without
  // tearing down the channel.
  bool _cancelled = false;

  // Probed once: whether this machine has a tar to extract the streamed archive.
  bool? _localTar;

  // Set while a tar stream is running, so a stop tears the pipe down at once
  // instead of waiting for the next chunk to notice the flag.
  void Function()? _onCancel;

  // A folder of small files is bound by round-trip latency, not bandwidth, so
  // keeping many requests in flight is what hides the latency.
  static const _maxConcurrentFiles = 16;

  @override
  void cancelTransfer() {
    _cancelled = true;
    _onCancel?.call();
  }

  void _throwIfCancelled() {
    if (_cancelled) throw const SftpCancelled();
  }

  @override
  Future<String> home() => _wrap(() => _sftp.absolute('.'));

  @override
  Future<List<RemoteFile>> list(String path) => _wrap(() async {
    final names = await _sftp.listdir(path);
    final files = await Future.wait([
      for (final name in names)
        if (name.filename != '.' && name.filename != '..')
          _resolve(_toRemoteFile(path, name)),
    ]);
    // Directories first, then case-insensitive by name, like a file manager.
    files.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return files;
  });

  // listdir reports a link's own attributes, so a link to a folder arrives
  // looking like a small file. stat follows the link; only links pay for it.
  Future<RemoteFile> _resolve(RemoteFile file) async {
    if (!file.isLink) return file;
    try {
      final target = await _sftp.stat(file.path);
      if (!target.isDirectory) return file;
      return RemoteFile(
        name: file.name,
        path: file.path,
        isDirectory: true,
        isLink: true,
        size: file.size,
        modified: file.modified,
      );
    } catch (e, st) {
      appLog("SFTP stat link failed", e, st);
      // A broken link stays as it is rather than failing the whole listing.
      return file;
    }
  }

  @override
  Future<bool> exists(String path) => _wrap(() async {
    try {
      await _sftp.stat(path);
      return true;
    } on SftpStatusError catch (e) {
      // 2 is "no such file", the only answer that means absent.
      if (e.code == 2) return false;
      rethrow;
    }
  });

  @override
  Future<void> makeDirectory(String path) => _wrap(() => _sftp.mkdir(path));

  @override
  Future<void> rename(String from, String to) =>
      _wrap(() => _sftp.rename(from, to));

  @override
  Future<void> setPermissions(String path, int permissions) => _wrap(
    () => _sftp.setStat(
      path,
      SftpFileAttrs(mode: SftpFileMode.value(permissions & 0x1FF)),
    ),
  );

  // Fetched once per session from the server's passwd/group databases. Empty
  // after a failed lookup, so an SFTP-only server is not retried every time.
  Map<int, String>? _uidNames;
  Map<int, String>? _gidNames;

  @override
  Future<({String owner, String group})> ownerNames(RemoteFile file) async {
    await _ensureOwnerMaps();
    String resolve(int? id, Map<int, String>? names) => id == null
        ? "unknown"
        : (names?[id] ?? id.toString());
    return (
      owner: resolve(file.uid, _uidNames),
      group: resolve(file.gid, _gidNames),
    );
  }

  @override
  Future<({Map<int, String> users, Map<int, String> groups})>
  ownerOptions() async {
    await _ensureOwnerMaps();
    return (
      users: _uidNames ?? const <int, String>{},
      groups: _gidNames ?? const <int, String>{},
    );
  }

  @override
  Future<void> setOwner(String path, {int? uid, int? gid}) => _wrap(
    // Only root may change ownership; a normal session gets permission denied.
    () => _sftp.setStat(path, SftpFileAttrs(userID: uid, groupID: gid)),
  );

  Future<void> _ensureOwnerMaps() async {
    if (_uidNames != null) return;
    _uidNames = await _idNameMap(
      'getent passwd 2>/dev/null || cat /etc/passwd 2>/dev/null',
    );
    _gidNames = await _idNameMap(
      'getent group 2>/dev/null || cat /etc/group 2>/dev/null',
    );
  }

  // Parses colon-separated passwd/group lines (name:x:id:...) into an id->name
  // map. A restricted or shell-less server just yields an empty map.
  Future<Map<int, String>> _idNameMap(String command) async {
    final map = <int, String>{};
    try {
      final output = await _client
          .run(command)
          .timeout(const Duration(seconds: 5));
      final text = utf8.decode(output, allowMalformed: true);
      for (final line in const LineSplitter().convert(text)) {
        final parts = line.split(':');
        if (parts.length < 3 || parts[0].isEmpty) continue;
        final id = int.tryParse(parts[2]);
        if (id != null) map.putIfAbsent(id, () => parts[0]);
      }
    } catch (e, st) {
      appLog("Owner name lookup failed", e, st);
    }
    return map;
  }

  @override
  Future<void> delete(RemoteFile file) =>
      _wrap(timeout: null, () => _deleteEntry(file));

  // rmdir needs an empty dir. Symlinks unlinked, never followed.
  Future<void> _deleteEntry(RemoteFile file) async {
    if (file.isLink || !file.isDirectory) {
      await _sftp.remove(file.path);
      return;
    }
    for (final name in await _sftp.listdir(file.path)) {
      if (name.filename == '.' || name.filename == '..') continue;
      await _deleteEntry(_toRemoteFile(file.path, name));
    }
    await _sftp.rmdir(file.path);
  }

  @override
  Future<Uint8List> readBytes(RemoteFile file, {required int maxBytes}) =>
      _wrap(timeout: null, () async {
        final remote = await _sftp.open(file.path, mode: SftpFileOpenMode.read);
        try {
          final builder = BytesBuilder(copy: false);
          await for (final chunk in remote.read(length: maxBytes)) {
            builder.add(chunk);
            if (builder.length >= maxBytes) break;
          }
          final bytes = builder.takeBytes();
          return bytes.length > maxBytes
              ? Uint8List.sublistView(bytes, 0, maxBytes)
              : bytes;
        } finally {
          await remote.close();
        }
      });

  @override
  Future<int> download(
    RemoteFile file,
    String localPath, {
    void Function(int bytes)? onProgress,
  }) => _wrap(timeout: null, () async {
    _cancelled = false;
    try {
      return await _copyToLocal(file.path, localPath, onProgress: onProgress);
    } on SftpCancelled {
      // A truncated file is indistinguishable from a whole one.
      await _deleteLocal(localPath);
      rethrow;
    }
  });

  // Consuming read() with await for pauses its request pipeline every chunk,
  // which costs most of the throughput. Cancellation rides the progress
  // callback instead, so download keeps its own tuning and backpressure.
  Future<int> _copyToLocal(
    String remotePath,
    String localPath, {
    int? length,
    void Function(int bytes)? onProgress,
  }) async {
    final sink = File(localPath).openWrite();
    try {
      return await _sftp.download(
        remotePath,
        sink,
        // Known from the listing, which saves a stat round trip per file.
        length: length,
        onProgress: (bytes) {
          _throwIfCancelled();
          onProgress?.call(bytes);
        },
      );
    } finally {
      await sink.close();
    }
  }

  Future<void> _deleteLocal(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      appLog("Delete local partial failed", e, st);
      // Nothing useful to do if the partial file will not go.
    }
  }

  @override
  Future<int> downloadDirectory(
    RemoteFile folder,
    String localPath, {
    void Function(int files, int bytes, String name)? onProgress,
  }) => _wrap(timeout: null, () async {
    _cancelled = false;
    // Streaming one tar over the shell saturates the link, where copying
    // hundreds of small files one by one is bound by round-trip latency. Fall
    // back to the per-file walk when the server or this machine has no tar.
    if (await _localTarAvailable()) {
      try {
        return await _downloadViaTar(folder, localPath, onProgress);
      } on SftpCancelled {
        await _deleteLocalDir(localPath);
        rethrow;
      } catch (e, st) {
        appLog("Tar download failed, using per-file transfer", e, st);
        await _deleteLocalDir(localPath);
      }
    }
    return _downloadViaSftp(folder, localPath, onProgress);
  });

  Future<int> _downloadViaSftp(
    RemoteFile folder,
    String localPath,
    void Function(int files, int bytes, String name)? onProgress,
  ) async {
    var files = 0;
    var bytes = 0;
    var skipped = 0;
    final gate = _ConcurrencyGate(_maxConcurrentFiles);
    final pending = <Future<void>>[];

    Future<void> copyOne(RemoteFile entry, String target) async {
      try {
        // Add after the await, never `bytes += await ...`: that reads bytes
        // before suspending, so concurrent files clobber each other's total.
        final written = await _copyToLocal(
          entry.path,
          target,
          length: entry.size > 0 ? entry.size : null,
        );
        bytes += written;
        onProgress?.call(++files, bytes, entry.name);
      } on SftpCancelled {
        await _deleteLocal(target);
        rethrow;
      } catch (e, st) {
        appLog("Skipped unreadable entry", e, st);
        // Skip unreadable entries, usually permission denied.
        skipped++;
      }
    }

    // Lists directories and starts each file download as soon as it is found,
    // so transfers overlap the walk instead of waiting for the whole tree to be
    // mapped. The gate bounds how many round trips run at once.
    Future<void> walk(String remoteDir, String localDir) async {
      await Directory(localDir).create(recursive: true);
      _throwIfCancelled();
      final listed = [
        for (final name in await gate.run(() => _sftp.listdir(remoteDir)))
          if (name.filename != '.' && name.filename != '..')
            _toRemoteFile(remoteDir, name),
      ];
      // A name with a separator or a parent reference would write outside the
      // download folder, so a malicious server's entries are dropped here.
      final safe = listed
          .where((e) => RemotePath.isSafeLocalSegment(e.name))
          .toList(growable: false);
      skipped += listed.length - safe.length;
      // Build caches and other junk are dropped silently, not counted as
      // skipped: they are never wanted in a copy of the sources.
      final entries = safe
          .where((e) => !_isIgnoredEntry(e))
          .toList(growable: false);
      // Recursing into a link could loop or escape the folder.
      final folders = entries.where((e) => e.isDirectory && !e.isLink);
      for (final entry in entries.where((e) => !e.isDirectory || e.isLink)) {
        final target = "$localDir/${entry.name}";
        pending.add(gate.run(() => copyOne(entry, target)));
      }
      await Future.wait([
        for (final f in folders) walk(f.path, "$localDir/${f.name}"),
      ]);
    }

    try {
      await walk(folder.path, localPath);
      await Future.wait(pending);
    } catch (_) {
      // Let in-flight downloads finish or clean up their partials, then report
      // the original failure.
      await Future.wait(pending).catchError((_) => <void>[]);
      rethrow;
    }
    return skipped;
  }

  // Streams the folder as one gzip tar over the shell and pipes it straight
  // into the local tar. --strip-components drops the top folder name so the
  // contents land inside the chosen destination even when it was renamed to
  // avoid a clash. Returns 0: the archive carries no per-file skip count.
  Future<int> _downloadViaTar(
    RemoteFile folder,
    String localPath,
    void Function(int files, int bytes, String name)? onProgress,
  ) async {
    await Directory(localPath).create(recursive: true);
    final command = _tarCommand(RemotePath.parentOf(folder.path), folder.name);
    final session = await _client.execute(command);
    // Extract into the destination via the process working directory, not tar's
    // -C: a Windows path is parsed differently by GNU tar and bsdtar, but the OS
    // sets the child's directory the same way for both.
    final Process extractor;
    try {
      extractor = await Process.start('tar', [
        '-x',
        '-z',
        '-v',
        '-f',
        '-',
        '--strip-components=1',
      ], workingDirectory: localPath);
    } catch (_) {
      session.close();
      rethrow;
    }

    var received = 0;
    var extracted = 0;
    var lastName = folder.name;
    // Extraction writes to disk, not stdout, but drain it so a full pipe can
    // never stall tar.
    final drain = extractor.stdout.listen((_) {});
    // tar writes -v names to stderr while the archive is on stdout, so this is
    // the live file feed for progress.
    final names = extractor.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final name = line.trim();
          if (name.isEmpty) return;
          extracted++;
          lastName = name.endsWith('/')
              ? name.substring(0, name.length - 1).split('/').last
              : name.split('/').last;
        });
    final remoteError = StringBuffer();
    final remoteErr = session.stderr
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(remoteError.write);

    // A stop kills the pipe now, rather than waiting for the next chunk. Any
    // failure while cancelled is reported as a cancel, so the caller stops
    // instead of falling back to the per-file download.
    _onCancel = () {
      extractor.kill();
      session.close();
    };

    try {
      await extractor.stdin.addStream(
        session.stdout.map((chunk) {
          received += chunk.length;
          onProgress?.call(extracted, received, lastName);
          return chunk;
        }),
      );
      await extractor.stdin.close();
      final localExit = await extractor.exitCode;
      await session.done;
      if (_cancelled) throw const SftpCancelled();
      final remoteExit = session.exitCode ?? 0;
      if (remoteExit != 0) {
        final detail = remoteError.toString().trim();
        throw SshConnectionException(
          detail.isEmpty ? "The server could not archive the folder." : detail,
        );
      }
      if (localExit != 0) {
        throw const SshConnectionException("Could not extract the download.");
      }
      return 0;
    } catch (_) {
      if (_cancelled) throw const SftpCancelled();
      rethrow;
    } finally {
      _onCancel = null;
      await drain.cancel();
      await names.cancel();
      await remoteErr.cancel();
      extractor.kill();
      session.close();
    }
  }

  Future<bool> _localTarAvailable() async {
    final cached = _localTar;
    if (cached != null) return cached;
    try {
      final result = await Process.run('tar', ['--version']);
      return _localTar = result.exitCode == 0;
    } catch (_) {
      return _localTar = false;
    }
  }

  String _tarCommand(String parent, String base) {
    final excludes = [
      for (final dir in _ignoredDirs) '*/$dir',
      for (final ext in _ignoredExtensions) '*$ext',
    ].map((pattern) => "--exclude=${_shellQuote(pattern)}").join(' ');
    return "tar -C ${_shellQuote(parent)} $excludes -czf - -- ${_shellQuote(base)}";
  }

  // Wraps a value so the remote shell passes it to tar literally, keeping globs
  // and paths safe from expansion or injection.
  String _shellQuote(String value) => "'${value.replaceAll("'", r"'\''")}'";

  Future<void> _deleteLocalDir(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e, st) {
      appLog("Delete local dir failed", e, st);
    }
  }

  static const _ignoredDirs = {'__pycache__', '.git'};
  static const _ignoredExtensions = {'.pyc', '.pyo'};

  bool _isIgnoredEntry(RemoteFile entry) =>
      _isIgnoredName(entry.name, entry.isDirectory);

  bool _isIgnoredName(String name, bool isDirectory) {
    if (isDirectory) return _ignoredDirs.contains(name);
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return false;
    return _ignoredExtensions.contains(name.substring(dot).toLowerCase());
  }

  // The exclude patterns as plain tar arguments, for the local archiver on
  // upload. The remote archiver on download builds them into a shell string.
  List<String> _tarExcludeArgs() => [
    for (final dir in _ignoredDirs) '--exclude=*/$dir',
    for (final ext in _ignoredExtensions) '--exclude=*$ext',
  ];

  // Last path segment, handling both Windows and POSIX local separators.
  String _baseName(String path) {
    final trimmed = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    return trimmed.substring(trimmed.lastIndexOf('/') + 1);
  }

  @override
  Future<void> upload(
    String localPath,
    String remotePath, {
    void Function(int bytes)? onProgress,
  }) => _wrap(timeout: null, () async {
    _cancelled = false;
    final remote = await _sftp.open(
      remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    var cancelled = false;
    try {
      final source = File(localPath).openRead().cast<Uint8List>().map((chunk) {
        _throwIfCancelled();
        return chunk;
      });
      await remote.write(source, onProgress: onProgress).done;
    } on SftpCancelled {
      cancelled = true;
      rethrow;
    } finally {
      await remote.close();
      // The half-written file would otherwise stand in for the real one.
      if (cancelled) await _sftp.remove(remotePath).catchError((_) {});
    }
  });

  @override
  Future<void> uploadDirectory(
    String localPath,
    String remoteDir, {
    void Function(int bytes)? onProgress,
  }) => _wrap(timeout: null, () async {
    _cancelled = false;
    // One local tar streamed into the server saturates the link; the per-file
    // walk is the fallback when either side has no tar.
    if (await _localTarAvailable()) {
      try {
        return await _uploadViaTar(localPath, remoteDir, onProgress);
      } on SftpCancelled {
        rethrow;
      } catch (e, st) {
        appLog("Tar upload failed, using per-file transfer", e, st);
      }
    }
    return _uploadViaSftp(localPath, remoteDir, onProgress);
  });

  // Streams a local gzip tar into the server's tar, which extracts it under
  // remoteDir. A stop kills the pipe and is reported as a cancel.
  Future<void> _uploadViaTar(
    String localPath,
    String remoteDir,
    void Function(int bytes)? onProgress,
  ) async {
    final directory = Directory(localPath);
    final parent = directory.parent.path;
    final base = _baseName(localPath);

    // Archive relative to the process directory, not tar's -C: a Windows path
    // is parsed differently by GNU tar and bsdtar, but the OS sets it the same.
    final producer = await Process.start('tar', [
      '-c',
      '-z',
      '-f',
      '-',
      ..._tarExcludeArgs(),
      '--',
      base,
    ], workingDirectory: parent);

    final SSHSession session;
    try {
      session = await _client.execute(
        'tar -x -z -f - -C ${_shellQuote(remoteDir)}',
      );
    } catch (_) {
      producer.kill();
      rethrow;
    }

    var sent = 0;
    final producerError = StringBuffer();
    final producerErr = producer.stderr
        .transform(utf8.decoder)
        .listen(producerError.write);
    final remoteError = StringBuffer();
    final remoteErr = session.stderr
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(remoteError.write);
    final remoteOut = session.stdout.listen((_) {});

    _onCancel = () {
      producer.kill();
      session.close();
    };

    try {
      await session.stdin.addStream(
        producer.stdout.cast<Uint8List>().map((chunk) {
          sent += chunk.length;
          onProgress?.call(sent);
          return chunk;
        }),
      );
      await session.stdin.close();
      final localExit = await producer.exitCode;
      await session.done;
      if (_cancelled) throw const SftpCancelled();
      if (localExit != 0) {
        final detail = producerError.toString().trim();
        throw SshConnectionException(
          detail.isEmpty ? "Could not read the local folder." : detail,
        );
      }
      final remoteExit = session.exitCode ?? 0;
      if (remoteExit != 0) {
        final detail = remoteError.toString().trim();
        throw SshConnectionException(
          detail.isEmpty ? "The server could not save the folder." : detail,
        );
      }
    } catch (_) {
      if (_cancelled) throw const SftpCancelled();
      rethrow;
    } finally {
      _onCancel = null;
      await producerErr.cancel();
      await remoteErr.cancel();
      await remoteOut.cancel();
      producer.kill();
      session.close();
    }
  }

  // Recreates the local folder on the server one file at a time, skipping build
  // caches. Files upload concurrently to hide per-file round trips.
  Future<void> _uploadViaSftp(
    String localPath,
    String remoteDir,
    void Function(int bytes)? onProgress,
  ) async {
    final root = RemotePath.join(remoteDir, _baseName(localPath));
    var sent = 0;
    final gate = _ConcurrencyGate(_maxConcurrentFiles);
    final pending = <Future<void>>[];

    Future<void> uploadOne(File local, String remotePath) async {
      final remote = await _sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      try {
        final source = local.openRead().cast<Uint8List>().map((chunk) {
          _throwIfCancelled();
          sent += chunk.length;
          onProgress?.call(sent);
          return chunk;
        });
        await remote.write(source).done;
      } finally {
        await remote.close();
      }
    }

    Future<void> walk(Directory localDir, String remotePath) async {
      _throwIfCancelled();
      await _sftp.mkdir(remotePath).catchError((_) {});
      await for (final entity in localDir.list(followLinks: false)) {
        _throwIfCancelled();
        final name = _baseName(entity.path);
        final isDir = entity is Directory;
        if (_isIgnoredName(name, isDir) ||
            !RemotePath.isSafeLocalSegment(name)) {
          continue;
        }
        final target = RemotePath.join(remotePath, name);
        if (isDir) {
          await walk(entity, target);
        } else if (entity is File) {
          pending.add(gate.run(() => uploadOne(entity, target)));
        }
      }
    }

    try {
      await walk(Directory(localPath), root);
      await Future.wait(pending);
    } catch (_) {
      await Future.wait(pending).catchError((_) => <void>[]);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _sftp.close();
    _client.close();
  }

  RemoteFile _toRemoteFile(String directory, SftpName name) {
    final attr = name.attr;
    final modified = attr.modifyTime;
    final mode = attr.mode;
    return RemoteFile(
      name: name.filename,
      path: RemotePath.join(directory, name.filename),
      isDirectory: attr.isDirectory,
      isLink: mode?.type == SftpFileType.symbolicLink,
      size: attr.size ?? 0,
      modified: modified == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(modified * 1000),
      // The low nine bits are the rwx permissions; the rest are the file type.
      permissions: mode == null ? null : mode.value & 0x1FF,
      uid: attr.userID,
      gid: attr.groupID,
    );
  }

  // Anything that only exchanges a request and a reply should answer quickly.
  // Transfers move real data and opt out with timeout: null.
  static const _operationTimeout = Duration(seconds: 30);

  // dartssh2 never completes a pending SFTP request when the transport dies, so
  // the loss has to be raced against it or the call waits forever.
  Future<T> _lost<T>() async {
    try {
      await _client.done;
    } catch (e, st) {
      appLog("SFTP transport wait failed", e, st);
      // The transport reports its own reason; only the outcome matters here.
    }
    throw const SshConnectionException(
      "The connection to the server was lost.",
    );
  }

  // SFTP errors arrive as protocol status codes, which are meaningless to a
  // user, so they are translated the same way connection errors are.
  Future<T> _wrap<T>(
    Future<T> Function() action, {
    Duration? timeout = _operationTimeout,
  }) async {
    try {
      final work = timeout == null ? action() : action().timeout(timeout);
      return await Future.any([work, _lost<T>()]);
    } on TimeoutException {
      throw const SshConnectionException("The server stopped responding.");
    } on SftpStatusError catch (e) {
      throw SshConnectionException(_message(e));
    } on SftpError catch (e) {
      throw SshConnectionException(e.message);
    } on FileSystemException catch (e) {
      throw SshConnectionException(
        "Could not use the local file: ${e.osError?.message ?? e.message}",
      );
    }
  }

  static String _message(SftpStatusError e) => switch (e.code) {
    2 => "That file or folder no longer exists.",
    3 => "Permission denied.",
    4 => "The server rejected the request.",
    _ => e.message,
  };
}

// Caps how many SFTP round trips run at once so a folder transfer keeps the
// link busy without opening an unbounded number of requests.
class _ConcurrencyGate {
  _ConcurrencyGate(this._free);
  int _free;
  final _waiters = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_free > 0) {
      _free--;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _free++;
    }
  }
}
