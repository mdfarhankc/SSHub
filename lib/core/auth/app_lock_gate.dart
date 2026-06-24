import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _promptOnResume = false;

  bool get _enabled =>
      context.read<SettingsCubit>().state.settings.appLockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_enabled) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_promptOnResume && !_authenticating) {
          _promptOnResume = false;
          _authenticate();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!context.read<LocalAuthService>().isAuthenticating) {
          _promptOnResume = true;
          setState(() => _locked = true);
        }
      default:
        break;
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await context.read<LocalAuthService>().authenticate(
      "Unlock SSHub",
    );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (p, c) =>
          p.settings.appLockEnabled != c.settings.appLockEnabled,
      builder: (context, state) {
        final showLock = state.settings.appLockEnabled && _locked;
        return Stack(
          children: [
            widget.child,
            if (showLock)
              Positioned.fill(
                child: _LockScreen(
                  authenticating: _authenticating,
                  onUnlock: _authenticate,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool authenticating;
  final VoidCallback onUnlock;
  const _LockScreen({required this.authenticating, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "SSHub Vault",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Locked for your security",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              if (authenticating)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Unlock Application"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
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
