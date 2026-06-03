import 'package:flutter/material.dart';

import 'package:ssh_manager/core/router/app_router.dart';
import 'package:ssh_manager/core/theme/app_theme.dart';
import 'package:ssh_manager/features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SSH Manager',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: SplashPage.route,
    );
  }
}
