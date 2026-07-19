import 'dart:io';

import 'package:flutter/services.dart';

import 'package:sshub/core/security/secure_platform.g.dart';

// Android-only hardening. Other platforms fall back to the plain clipboard.
abstract final class SecurePlatform {
  static final _api = SecurePlatformApi();

  // The activity enables it at launch, so this only turns it off.
  static Future<void> setBlockScreenshots(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _api.setBlockScreenshots(enabled);
    } on PlatformException {
      // Older build without the bridge.
    } on MissingPluginException {
      // Same.
    }
  }

  // Keeps tokens out of keyboard clipboard previews.
  static Future<void> copySensitive(String text) async {
    if (Platform.isAndroid) {
      try {
        await _api.copySensitive(text);
        return;
      } on PlatformException {
        // Fall through.
      } on MissingPluginException {
        // Same.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }
}
