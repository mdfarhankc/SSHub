import 'dart:typed_data';

import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

// Thrown by a transfer the user stopped.
class SftpCancelled implements Exception {
  const SftpCancelled();
}

// Thrown by a transfer the user paused. Unlike a cancel, the partial is kept so
// the transfer can resume from where it stopped.
class SftpPaused implements Exception {
  const SftpPaused();
}

// A live SFTP channel. Paths are POSIX and absolute. Failures surface as
// SshConnectionException so the browser reports them like any other SSH error.
abstract interface class SftpSession {
  // Stops the running transfer at its next chunk or entry.
  void cancelTransfer();

  // Pauses the running transfer, keeping the partial so it can resume. Only
  // single-file transfers resume; a folder transfer would restart.
  void pauseTransfer();

  // The size of the remote file at [path] in bytes, or 0 if it is missing. Used
  // to resume an upload from what already landed.
  Future<int> fileSize(String path);

  // Absolute path of the login directory, the browser's starting point.
  Future<String> home();

  Future<List<RemoteFile>> list(String path);

  Future<bool> exists(String path);

  Future<void> makeDirectory(String path);

  Future<void> rename(String from, String to);

  // Sets the Unix permission bits (0-0o777) on the entry at [path].
  Future<void> setPermissions(String path, int permissions);

  // Resolves the owning user and group of [file] to names, falling back to the
  // numeric ids when they cannot be looked up.
  Future<({String owner, String group})> ownerNames(RemoteFile file);

  // The server's known users and groups as id->name maps, for an owner picker.
  Future<({Map<int, String> users, Map<int, String> groups})> ownerOptions();

  // Changes the owner and/or group of the entry at [path]. Requires root.
  Future<void> setOwner(String path, {int? uid, int? gid});

  Future<void> delete(RemoteFile file);

  // Removes the file at [path]. Used to clean up a partial left by a cancelled
  // paused upload.
  Future<void> deletePath(String path);

  // Reads at most [maxBytes] from the start of [file]. Bounded because the
  // result is held in memory, unlike download, which streams to disk.
  Future<Uint8List> readBytes(RemoteFile file, {required int maxBytes});

  // Overwrites the file at [path] with [bytes], creating it if missing and
  // truncating any previous content. Used to save an edited text file.
  Future<void> writeBytes(String path, Uint8List bytes);

  // Streams [file] into [localPath] and returns the bytes written. Progress is
  // reported as a running total, not a delta. [resumeFrom] continues a paused
  // download, appending from that byte offset instead of starting over.
  Future<int> download(
    RemoteFile file,
    String localPath, {
    int resumeFrom = 0,
    void Function(int bytes)? onProgress,
  });

  // Mirrors [folder] into [localPath], transferring as the walk finds entries.
  // Returns the number skipped because they could not be read.
  Future<int> downloadDirectory(
    RemoteFile folder,
    String localPath, {
    void Function(int files, int bytes, String name)? onProgress,
  });

  // [resumeFrom] continues a paused upload, sending from that byte offset onto
  // the partial already on the server instead of truncating and starting over.
  Future<void> upload(
    String localPath,
    String remotePath, {
    int resumeFrom = 0,
    void Function(int bytes)? onProgress,
  });

  // Uploads the local folder at [localPath] into [remoteDir], creating a folder
  // of the same name under it.
  Future<void> uploadDirectory(
    String localPath,
    String remoteDir, {
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
