import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/repositories/backup_repository_impl.dart';
import 'package:sshub/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/ssh/data/datasources/secret_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_connection_repository_impl.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_repository_impl.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

class AppRepositoryProviders extends StatelessWidget {
  final Widget child;
  const AppRepositoryProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SshRepository>(
          create: (_) => const SshRepositoryImpl(
            ServerLocalDatasource(),
            SecretDatasource(),
          ),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) =>
              const SettingsRepositoryImpl(SettingsLocalDatasource()),
        ),
        RepositoryProvider<SshConnectionRepository>(
          create: (_) => const SshConnectionRepositoryImpl(),
        ),
        RepositoryProvider<BackupRepository>(
          create: (_) => const BackupRepositoryImpl(
            ServerLocalDatasource(),
            SecretDatasource(),
            SettingsLocalDatasource(),
          ),
        ),
      ],
      child: child,
    );
  }
}
