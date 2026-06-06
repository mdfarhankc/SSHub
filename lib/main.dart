import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ssh_manager/core/router/app_router.dart';
import 'package:ssh_manager/core/theme/app_theme.dart';
import 'package:ssh_manager/features/splash/presentation/pages/splash_page.dart';
import 'package:ssh_manager/features/ssh/data/datasources/secret_datasource.dart';
import 'package:ssh_manager/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:ssh_manager/features/ssh/data/repositories/ssh_repository_impl.dart';
import 'package:ssh_manager/features/ssh/domain/repositories/ssh_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SshRepository>(
      create: (_) =>
          const SshRepositoryImpl(ServerLocalDatasource(), SecretDatasource()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SSHub',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: SplashPage.route,
      ),
    );
  }
}
