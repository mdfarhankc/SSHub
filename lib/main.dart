import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/providers/app_bloc_providers.dart';
import 'package:sshub/core/providers/app_repository_providers.dart';
import 'package:sshub/core/router/app_router.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await const SettingsRepositoryImpl(
    SettingsLocalDatasource(),
  ).load();
  runApp(MyApp(initialSettings: settings));
}

class MyApp extends StatelessWidget {
  final AppSettings initialSettings;
  const MyApp({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context) {
    return AppRepositoryProviders(
      child: AppBlocProviders(
        initialSettings: initialSettings,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeAnimationDuration: Duration.zero,
              title: 'SSHub',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: switch (state.settings.themeMode) {
                AppThemeMode.system => ThemeMode.system,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
              },
              onGenerateRoute: AppRouter.onGenerateRoute,
              onGenerateInitialRoutes: (initialRoute) => [
                AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
              ],
              initialRoute: SplashPage.route,
            );
          },
        ),
      ),
    );
  }
}
