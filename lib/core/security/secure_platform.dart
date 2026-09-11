import 'dart:io';

import 'package:flutter/services.dart';

import 'package:sshub/core/security/secure_platform.g.dart';

// Native hardening. Screen-capture blocking runs where it can be enforced;
// the clipboard hardening stays Android-only and falls back elsewhere.
abstract final class SecurePlatform {
  static final _api = SecurePlatformApi();
  static const _window = MethodChannel('sshub/secure_window');

  // Platforms where screen capture can actually be blocked. Linux and iOS have
  // no reliable way to enforce it, so the setting is not offered there.
  static bool get canBlockScreenshots =>
      Platform.isAndroid || Platform.isWindows || Platform.isMacOS;

  // Applies the value: Android via FLAG_SECURE, desktop via the window's capture
  // affinity. Desktop has no secure default, so the caller must apply it.
  static Future<void> setBlockScreenshots(bool enabled) async {
    try {
      if (Platform.isAndroid) {
        await _api.setBlockScreenshots(enabled);
      } else if (Platform.isWindows || Platform.isMacOS) {
        await _window.invokeMethod('setBlockScreenshots', enabled);
      }
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
