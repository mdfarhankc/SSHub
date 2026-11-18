import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';

// Whether servers behind a locked tag are currently revealed. Starts hidden on
// a cold launch and re-hides whenever the app is backgrounded, so walking away
// re-locks them.
class HiddenServersCubit extends Cubit<bool> with WidgetsBindingObserver {
  final LocalAuthService _auth;

  // Without a device lock the hide cannot be enforced, so locked servers stay
  // revealed rather than being stranded with no way to unlock them.
  bool _enforceable = true;

  // False once we know the device has no lock: hiding is off for good, so the
  // UI can drop the reveal controls instead of showing ones that do nothing.
  bool get canEnforce => _enforceable;

  HiddenServersCubit(this._auth) : super(false) {
    WidgetsBinding.instance.addObserver(this);
    _auth.isAvailable().then((available) {
      if (available || isClosed) return;
      _enforceable = false;
      if (!state) emit(true);
    });
  }

  void reveal() {
    if (_enforceable && !state) emit(true);
  }

  void hide() {
    if (_enforceable && state) emit(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enforceable) return;
    final leaving =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    // Our own biometric prompt backgrounds the app; that is not the user
    // leaving, so it must not re-hide what they just unlocked.
    if (leaving && !_auth.isAuthenticating) hide();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
