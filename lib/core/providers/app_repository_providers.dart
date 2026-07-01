import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/repositories/backup_repository_impl.dart';
import 'package:sshub/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/snippets/data/datasources/snippet_local_datasource.dart';
import 'package:sshub/features/snippets/data/repositories/snippet_repository_impl.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_local_datasource.dart';
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
          create: (_) => const SshRepositoryImpl(ServerLocalDatasource()),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) =>
              const SettingsRepositoryImpl(SettingsLocalDatasource()),
        ),
        RepositoryProvider<SshConnectionRepository>(
          create: (_) =>
              const SshConnectionRepositoryImpl(KnownHostsLocalDatasource()),
        ),
        RepositoryProvider<SnippetRepository>(
          create: (_) => const SnippetRepositoryImpl(SnippetLocalDatasource()),
        ),
        RepositoryProvider<LocalAuthService>(create: (_) => LocalAuthService()),
        RepositoryProvider<BackupRepository>(
          create: (_) => const BackupRepositoryImpl(
            ServerLocalDatasource(),
            SettingsLocalDatasource(),
            SnippetLocalDatasource(),
          ),
        ),
      ],
      child: child,
    );
  }
}
