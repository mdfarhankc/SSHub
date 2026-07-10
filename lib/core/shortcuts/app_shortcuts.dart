import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

bool get _isApple => Platform.isMacOS || Platform.isIOS;

/// Label for the primary shortcut modifier on this platform.
String get shortcutModifierLabel => _isApple ? "Cmd" : "Ctrl";

/// Binds [key] to [callback] using the platform's primary modifier.
Map<ShortcutActivator, VoidCallback> shortcutBinding(
  LogicalKeyboardKey key,
  VoidCallback callback, {
  bool shift = false,
}) {
  final activator = _isApple
      ? SingleActivator(key, meta: true, shift: shift)
      : SingleActivator(key, control: true, shift: shift);
  return {activator: callback};
}
