import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/ssh/data/datasources/reachability_checker.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

class AppBlocProviders extends StatelessWidget {
  final Widget child;
  final AppSettings initialSettings;
  const AppBlocProviders({
    super.key,
    required this.child,
    required this.initialSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              SettingsCubit(sl<SettingsRepository>(), initialSettings),
        ),
        BlocProvider(
          create: (_) => ServerListBloc(
            sl<SshRepository>(),
            checker: sl<ReachabilityChecker>(),
          )..add(ServerListLoaded()),
        ),
        BlocProvider(
          create: (_) =>
              SnippetListBloc(sl<SnippetRepository>())
                ..add(SnippetListLoaded()),
        ),
        BlocProvider(create: (_) => BackupCubit(sl<BackupRepository>())),
      ],
      child: child,
    );
  }
}
