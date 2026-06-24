import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';

class _Slide {
  final IconData icon;
  final String? hero;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    this.hero,
    required this.title,
    required this.body,
  });
}

const _slides = <_Slide>[
  _Slide(
    icon: Icons.dns_rounded,
    title: "Welcome to SSHub",
    body:
        "A fast, minimal SSH client for your machine. Keep all your servers "
        "in one place.",
  ),
  _Slide(
    icon: Icons.bolt_rounded,
    title: "Connect in one tap",
    body:
        "Save servers with labels, colors, and notes, then open a session "
        "with a single click.",
  ),
  _Slide(
    icon: Icons.terminal_rounded,
    title: "Built-in terminal",
    body:
        "Work in a full terminal right inside the app. No external windows, "
        "no extra tools.",
  ),
  _Slide(
    icon: Icons.lock_rounded,
    hero: "100%",
    title: "Local and secure",
    body:
        "Your servers and passwords never leave this device. Everything is "
        "stored locally, encrypted by your operating system, and guarded by "
        "app lock. Nothing is ever uploaded to any server or cloud.",
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  static const route = "/onboarding";

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    context.read<SettingsCubit>().completeOnboarding();
    Navigator.pushReplacementNamed(context, HomePage.route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: const Text("Skip"),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: i == _page ? 24 : 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(_isLast ? "Get Started" : "Next"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (slide.hero != null)
                _HeroBadge(text: slide.hero!, icon: slide.icon)
              else
                Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.18),
                        scheme.primary.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Icon(slide.icon, size: 76, color: scheme.primary),
                ),
              const SizedBox(height: 40),
              if (slide.hero != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(slide.icon, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      slide.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const _HeroBadge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.14),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ).createShader(rect),
        child: Text(
          text,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -3,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
