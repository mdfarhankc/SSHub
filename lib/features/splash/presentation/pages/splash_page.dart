import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static const route = "/";

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;
  bool _minDelayPassed = false;

  @override
  void initState() {
    super.initState();
    // Keep the splash on screen for at least a moment, even if data is ready.
    Future.delayed(const Duration(seconds: 1), () {
      _minDelayPassed = true;
      _goHome();
    });
  }

  bool _loaded(ServerListState state) =>
      state.status == ServerListStatus.success ||
      state.status == ServerListStatus.failure;

  void _goHome() {
    if (_navigated || !mounted || !_minDelayPassed) return;
    if (!_loaded(context.read<ServerListBloc>().state)) return;
    _navigated = true;
    final onboarded =
        context.read<SettingsCubit>().state.settings.onboardingComplete;
    Navigator.pushReplacementNamed(
      context,
      onboarded ? HomePage.route : OnboardingPage.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocListener<ServerListBloc, ServerListState>(
        listenWhen: (_, current) => _loaded(current),
        listener: (_, _) => _goHome(),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        "assets/icon/icon_without_bg.png",
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "SSHub",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  "SECURE • FAST • SIMPLE",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
