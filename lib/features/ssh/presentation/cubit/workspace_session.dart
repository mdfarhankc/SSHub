import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

// A tab in the workspace is one of these. Terminal and file sessions live side
// by side in the same strip, so they share this shape.
enum WorkspaceKind { terminal, files }

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
