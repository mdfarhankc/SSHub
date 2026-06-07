import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/router/app_router.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';
import 'package:sshub/features/ssh/data/datasources/secret_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_connection_repository_impl.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_repository_impl.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ],
      child: BlocProvider(
        create: (context) => SettingsCubit(context.read<SettingsRepository>()),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SSHub',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: switch (state.settings.themeMode) {
                AppThemeMode.system => ThemeMode.system,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
              },
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: SplashPage.route,
            );
          },
        ),
      ),
    );
  }
}
