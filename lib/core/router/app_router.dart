import 'package:flutter/material.dart';

import 'package:sshub/features/help/presentation/pages/help_page.dart';
import 'package:sshub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';
import 'package:sshub/features/ssh/presentation/pages/workspace_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.route:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case OnboardingPage.route:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case HomePage.route:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case WorkspacePage.route:
        return MaterialPageRoute(builder: (_) => const WorkspacePage());
      case SettingsPage.route:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case SnippetsPage.route:
        return MaterialPageRoute(builder: (_) => const SnippetsPage());
      case HelpPage.route:
        return MaterialPageRoute(builder: (_) => const HelpPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("404"))),
        );
    }
  }
}
