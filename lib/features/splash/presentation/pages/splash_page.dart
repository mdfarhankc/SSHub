import 'dart:math' as math;

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

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  bool _navigated = false;
  bool _minDelayPassed = false;
  bool _timedOut = false;

  late final AnimationController _entrance;
  // The handoff zoom runs on the splash itself, before Home is pushed, so it
  // plays smoothly instead of competing with Home's first build on the UI
  // thread (which in a debug desktop build would eat the frames).
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addStatusListener(_onExitDone);
    // Hold the splash long enough for its entrance to finish and settle before
    // handing off, even if data is ready sooner.
    Future.delayed(const Duration(milliseconds: 1400), () {
      _minDelayPassed = true;
      _goHome();
    });
    // Storage that never answers would otherwise hold the splash for good.
    Future.delayed(const Duration(seconds: 8), () {
      _timedOut = true;
      _goHome();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  bool _loaded(ServerListState state) =>
      state.status == ServerListStatus.success ||
      state.status == ServerListStatus.failure;

  void _goHome() {
    if (_navigated || !mounted || !_minDelayPassed) return;
    if (!_timedOut && !_loaded(context.read<ServerListBloc>().state)) return;
    _navigated = true;
    _exit.forward();
  }

  void _onExitDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final onboarded = context
        .read<SettingsCubit>()
        .state
        .settings
        .onboardingComplete;
    Navigator.pushReplacementNamed(
      context,
      onboarded ? HomePage.route : OnboardingPage.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final entrance = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocListener<ServerListBloc, ServerListState>(
        listenWhen: (_, current) => _loaded(current),
        listener: (_, _) => _goHome(),
        // On handoff the splash rushes into the logo and fades, as if the
        // camera flies through it, then Home fades in beneath.
        child: AnimatedBuilder(
          animation: _exit,
          builder: (context, child) {
            final t = Curves.easeIn.transform(_exit.value);
            return Opacity(
              opacity: 1 - t,
              child: Transform.scale(scale: 1 + t * 4, child: child),
            );
          },
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: entrance,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.82, end: 1.0).animate(entrance),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.25),
                                blurRadius: 48,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              "assets/icon/icon_green.png",
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "SSHub",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _LoadingDots(color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: entrance,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Three dots pulsing in a wave, a lighter-weight loader than a spinner.
class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          // Each dot trails the one before it, so the pulse reads as a wave.
          final phase = (_controller.value - i * 0.18) % 1.0;
          final wave = math.sin(phase * math.pi).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: 0.8 + 0.4 * wave,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.3 + 0.7 * wave),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
