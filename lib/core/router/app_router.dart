import 'package:flutter/material.dart';

import 'package:sshub/features/help/presentation/pages/help_page.dart';
import 'package:sshub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/splash/presentation/pages/splash_page.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';
import 'package:sshub/features/ssh/presentation/pages/workspace_page.dart';
import 'package:sshub/features/workflows/presentation/pages/workflows_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.route:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case OnboardingPage.route:
        return _fadeRoute(const OnboardingPage(), settings);
      case HomePage.route:
        return _fadeRoute(const HomePage(), settings);
      case WorkspacePage.route:
        return MaterialPageRoute(builder: (_) => const WorkspacePage());
      case SettingsPage.route:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case SnippetsPage.route:
        return MaterialPageRoute(builder: (_) => const SnippetsPage());
      case WorkflowsPage.route:
        return MaterialPageRoute(builder: (_) => const WorkflowsPage());
      case HelpPage.route:
        return MaterialPageRoute(builder: (_) => const HelpPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("404"))),
        );
    }
  }

  // Used for the app-entry pages. Home fades in and settles from a slight
  // zoom, so it reads as emerging from behind the splash as it rushes past.
  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 1.08, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
