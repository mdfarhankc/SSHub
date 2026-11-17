import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';

// Folders open in place; a file opens as its own workspace tab, borrowing this
// browser's connection.
void openRemoteFile(BuildContext context, RemoteFile file, SftpCubit cubit) {
  if (file.isDirectory) {
    cubit.openDirectory(file);
    return;
  }
  context.read<WorkspaceSessionsCubit>().openFileViewer(file, cubit);
}
