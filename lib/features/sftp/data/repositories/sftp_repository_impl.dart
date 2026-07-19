import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

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
    } catch (_) {
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

  static const _maxConcurrentFiles = 6;

  @override
  void cancelTransfer() => _cancelled = true;

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
    } catch (_) {
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
    } catch (_) {
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
    var files = 0;
    var bytes = 0;
    var skipped = 0;

    Future<void> copyOne(RemoteFile entry, String target) async {
      try {
        bytes += await _copyToLocal(
          entry.path,
          target,
          length: entry.size > 0 ? entry.size : null,
        );
        onProgress?.call(++files, bytes, entry.name);
      } on SftpCancelled {
        await _deleteLocal(target);
        rethrow;
      } catch (_) {
        // Skip unreadable entries, usually permission denied.
        skipped++;
      }
    }

    Future<void> walk(String remoteDir, String localDir) async {
      await Directory(localDir).create(recursive: true);
      _throwIfCancelled();
      final entries = [
        for (final name in await _sftp.listdir(remoteDir))
          if (name.filename != '.' && name.filename != '..')
            _toRemoteFile(remoteDir, name),
      ];
      // Recursing into a link could loop or escape the folder.
      final folders = entries.where((e) => e.isDirectory && !e.isLink);
      final plain = entries
          .where((e) => !e.isDirectory || e.isLink)
          .toList(growable: false);

      // A small file costs a round trip far more than it costs bandwidth, so
      // several are in flight at once.
      for (var i = 0; i < plain.length; i += _maxConcurrentFiles) {
        _throwIfCancelled();
        await Future.wait([
          for (final entry in plain.skip(i).take(_maxConcurrentFiles))
            copyOne(entry, "$localDir/${entry.name}"),
        ]);
      }

      for (final folder in folders) {
        await walk(folder.path, "$localDir/${folder.name}");
      }
    }

    await walk(folder.path, localPath);
    return skipped;
  });

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
  Future<void> close() async {
    _sftp.close();
    _client.close();
  }

  RemoteFile _toRemoteFile(String directory, SftpName name) {
    final attr = name.attr;
    final modified = attr.modifyTime;
    return RemoteFile(
      name: name.filename,
      path: RemotePath.join(directory, name.filename),
      isDirectory: attr.isDirectory,
      isLink: attr.mode?.type == SftpFileType.symbolicLink,
      size: attr.size ?? 0,
      modified: modified == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(modified * 1000),
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
    } catch (_) {
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
