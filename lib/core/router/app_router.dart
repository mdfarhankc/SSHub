import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';
import 'package:sshub/features/ssh/presentation/pages/terminal_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.route:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case OnboardingPage.route:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case HomePage.route:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case TerminalPage.route:
        final server = settings.arguments as SshServer;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => TerminalCubit(
              ConnectToServer(context.read<SshConnectionRepository>()),
              server,
            ),
            child: TerminalPage(server: server),
          ),
        );
      case SettingsPage.route:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case SnippetsPage.route:
        return MaterialPageRoute(builder: (_) => const SnippetsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("404"))),
        );
    }
  }
}
