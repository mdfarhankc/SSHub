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

  const _DartSftpSession(this._client, this._sftp);

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
  Future<void> makeDirectory(String path) => _wrap(() => _sftp.mkdir(path));

  @override
  Future<void> rename(String from, String to) =>
      _wrap(() => _sftp.rename(from, to));

  @override
  Future<void> delete(RemoteFile file) => _wrap(
    () => file.isDirectory ? _sftp.rmdir(file.path) : _sftp.remove(file.path),
  );

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
    final sink = File(localPath).openWrite();
    try {
      return await _sftp.download(file.path, sink, onProgress: onProgress);
    } finally {
      await sink.close();
    }
  });

  @override
  Future<void> upload(
    String localPath,
    String remotePath, {
    void Function(int bytes)? onProgress,
  }) => _wrap(timeout: null, () async {
    final remote = await _sftp.open(
      remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    try {
      final source = File(localPath).openRead().cast<Uint8List>();
      await remote.write(source, onProgress: onProgress).done;
    } finally {
      await remote.close();
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
