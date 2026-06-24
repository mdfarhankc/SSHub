import 'dart:io';

import 'package:local_auth/local_auth.dart';

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

  Future<bool> authenticate(String reason) async {
    if (!_supported) return true;
    _busy = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      return true;
    } finally {
      _busy = false;
    }
  }
}
