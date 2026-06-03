import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ssh_manager/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:ssh_manager/features/splash/presentation/pages/splash_page.dart';
import 'package:ssh_manager/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:ssh_manager/features/ssh/presentation/pages/home_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.route:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => SplashCubit(),
            child: const SplashPage(),
          ),
        );
      case HomePage.route:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => ServerListBloc()..add(ServerListLoaded()),
            child: const HomePage(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("404"))),
        );
    }
  }
}
