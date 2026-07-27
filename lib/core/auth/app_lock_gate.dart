import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';
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
  DateTime? _leftAt;
  Timer? _idleTimer;

  bool get _enabled =>
      context.read<SettingsCubit>().state.settings.appLockEnabled;
  int get _timeout =>
      context.read<SettingsCubit>().state.settings.autoLockMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    // A cold start always locks; the timeout only governs re-locking.
    if (_enabled) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    } else {
      _armIdle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idleTimer?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent _) {
    _onActivity();
    return false;
  }

  void _onActivity() {
    if (!_locked) _armIdle();
  }

  // Restarted on every interaction. When it fires, the app has been idle long
  // enough to lock.
  void _armIdle() {
    _idleTimer?.cancel();
    if (_enabled && _timeout > 0 && !_locked) {
      _idleTimer = Timer(Duration(minutes: _timeout), () {
        if (mounted && _enabled && !_locked) setState(() => _locked = true);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        // No recorded pause means the app never actually backgrounded, just a
        // transient inactive from the keyboard or a focus change. Re-locking
        // here is what made the lock fire on every field tap.
        if (left == null) {
          _armIdle();
          break;
        }
        final away = DateTime.now().difference(left);
        // -1 never re-locks; 0 locks on any leave; else after the timeout away.
        final shouldLock =
            _timeout >= 0 &&
            (_timeout == 0 || away >= Duration(minutes: _timeout));
        if (shouldLock) {
          if (!_authenticating) _authenticate();
        } else {
          setState(() => _locked = false);
          _armIdle();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Our own biometric prompt backgrounds the app; that is not the user
        // leaving, so it must not record a leave or hide the content.
        if (sl<LocalAuthService>().isAuthenticating) break;
        _leftAt = DateTime.now();
        _idleTimer?.cancel();
        // Content is hidden while away no matter the timeout; resume decides
        // whether re-auth is required.
        setState(() => _locked = true);
      default:
        break;
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final result = await sl<LocalAuthService>().authenticate("Unlock SSHub");
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      // Staying locked when there is nothing to authenticate against would shut
      // the user out for good. Settings warns that the lock is unenforceable.
      if (result != AuthResult.failed) _locked = false;
    });
    _armIdle();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      // Re-arm when the timeout changes, and rebuild when the lock is toggled.
      listenWhen: (p, c) =>
          p.settings.autoLockMinutes != c.settings.autoLockMinutes ||
          p.settings.appLockEnabled != c.settings.appLockEnabled,
      listener: (_, _) => _armIdle(),
      buildWhen: (p, c) =>
          p.settings.appLockEnabled != c.settings.appLockEnabled,
      builder: (context, state) {
        final showLock = state.settings.appLockEnabled && _locked;
        return Listener(
          onPointerDown: (_) => _onActivity(),
          onPointerMove: (_) => _onActivity(),
          child: Stack(
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
          ),
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
            colors: [scheme.surface, scheme.surfaceContainer],
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
                child: Icon(LucideIcons.lock, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 32),
              Text(
                "SSHub Vault",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: scheme.primary,
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
                  icon: const Icon(LucideIcons.fingerprint),
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
