import 'dart:io';

import 'package:local_auth/local_auth.dart';

// unavailable means the device has no lock to check against, which callers must
// not treat as a pass.
enum AuthResult { success, failed, unavailable }

class LocalAuthService {
  final LocalAuthentication _auth;
  LocalAuthService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  bool get _supported => !Platform.isLinux;

  bool _busy = false;
  bool get isAuthenticating => _busy;

  Future<bool> isAvailable() async {
    if (!_supported) return false;
    try {
      return await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  Future<AuthResult> authenticate(String reason) async {
    if (!_supported) return AuthResult.unavailable;
    _busy = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthResult.success : AuthResult.failed;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          return AuthResult.unavailable;
        default:
          return AuthResult.failed;
      }
    } on Exception {
      return AuthResult.failed;
    } finally {
      _busy = false;
    }
  }
}
