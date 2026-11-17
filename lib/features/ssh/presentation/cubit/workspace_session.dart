import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/file_viewer_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

// A tab in the workspace is one of these. Terminal, file browser and open-file
// tabs live side by side in the same strip, so they share this shape.
enum WorkspaceKind { terminal, files, fileViewer }

sealed class WorkspaceSession {
  SshServer get server;
  WorkspaceKind get kind;
  Future<void> close();
}

class TerminalWorkspaceSession extends WorkspaceSession {
  final TerminalCubit cubit;
  TerminalWorkspaceSession(this.cubit);

  @override
  SshServer get server => cubit.server;

  @override
  WorkspaceKind get kind => WorkspaceKind.terminal;

  @override
  Future<void> close() => cubit.close();
}

class FileWorkspaceSession extends WorkspaceSession {
  final SftpCubit cubit;
  FileWorkspaceSession(this.cubit);

  @override
  SshServer get server => cubit.server;

  @override
  WorkspaceKind get kind => WorkspaceKind.files;

  @override
  Future<void> close() => cubit.close();
}

// A file opened from a browser tab. It borrows that browser's SFTP connection
// ([source]) for reading, saving and downloading, so closing the browser closes
// this too.
class FileViewerWorkspaceSession extends WorkspaceSession {
  final FileViewerCubit cubit;
  final SftpCubit source;
  final RemoteFile file;
  FileViewerWorkspaceSession(this.cubit, this.source, this.file);

  @override
  SshServer get server => source.server;

  @override
  WorkspaceKind get kind => WorkspaceKind.fileViewer;

  // Only the viewer's own cubit is closed; the borrowed connection belongs to
  // the browser tab.
  @override
  Future<void> close() => cubit.close();
}
