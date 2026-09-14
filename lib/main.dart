import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/app_info.dart';
import 'package:sshub/core/app_startup.dart';
import 'package:sshub/core/auth/app_lock_gate.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/providers/app_bloc_providers.dart';
import 'package:sshub/core/router/app_router.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  silenceHarmlessKeyAssertion();
  setupLocator();

  final settings = await sl<SettingsRepository>().load();
  await applyScreenshotBlocking(settings);
  runApp(MyApp(initialSettings: settings));
}

class MyApp extends StatelessWidget {
  final AppSettings initialSettings;

  const MyApp({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context) {
    return AppBlocProviders(
      initialSettings: initialSettings,
      child: BlocSelector<SettingsCubit, SettingsState, ThemeMode>(
        selector: (state) => state.settings.themeMode,
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeAnimationDuration: Duration.zero,
            title: AppInfo.name,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: SplashPage.route,
            builder: (context, child) =>
                AppLockGate(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
