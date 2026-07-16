import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/sftp/domain/usecases/open_sftp_session.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/pages/sftp_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
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
        return MaterialPageRoute(builder: (_) => const TerminalPage());
      case SftpPage.route:
        final server = settings.arguments as SshServer;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => SftpCubit(
              sl<OpenSftpSession>(),
              server,
              context.read<SettingsCubit>(),
            ),
            child: const SftpPage(),
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
