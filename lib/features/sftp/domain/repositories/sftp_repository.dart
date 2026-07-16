import 'dart:typed_data';

import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

// A live SFTP channel. Paths are POSIX and absolute. Failures surface as
// SshConnectionException so the browser reports them like any other SSH error.
abstract interface class SftpSession {
  // Absolute path of the login directory, the browser's starting point.
  Future<String> home();

  Future<List<RemoteFile>> list(String path);

  Future<void> makeDirectory(String path);

  Future<void> rename(String from, String to);

  Future<void> delete(RemoteFile file);

  // Reads at most [maxBytes] from the start of [file]. Bounded because the
  // result is held in memory, unlike download, which streams to disk.
  Future<Uint8List> readBytes(RemoteFile file, {required int maxBytes});

  // Streams [file] into [localPath] and returns the bytes written. Progress is
  // reported as a running total, not a delta.
  Future<int> download(
    RemoteFile file,
    String localPath, {
    void Function(int bytes)? onProgress,
  });

  Future<void> upload(
    String localPath,
    String remotePath, {
    void Function(int bytes)? onProgress,
  });

  Future<void> close();
}

abstract interface class SftpRepository {
  Future<SftpSession> connect(
    SshServer server, {
    String? password,
    String? privateKey,
    String? keyPassphrase,
  });
}
