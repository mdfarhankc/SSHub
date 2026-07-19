import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/file_viewer_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/pages/file_viewer_page.dart';

// Folders open in place; files push the viewer, which borrows this session.
void openRemoteFile(BuildContext context, RemoteFile file, SftpCubit cubit) {
  if (file.isDirectory) {
    cubit.openDirectory(file);
    return;
  }
  final session = cubit.session;
  if (session == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(create: (_) => FileViewerCubit(session, file)),
        ],
        child: const FileViewerPage(),
      ),
    ),
  );
}
