import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:sshub/core/security/secure_platform.g.dart';

// Native terminal bell. Each OS beeps its own way through the symbols its
// Flutter embedder already loads, so nothing extra has to be bundled or linked.
// Every path is guarded; a failed lookup falls back to the framework sound
// rather than throwing into the terminal.
abstract final class SystemBell {
  static final _api = SecurePlatformApi();

  static void Function(int)? _windowsBeep;
  static void Function()? _macBeep;
  static void Function(int)? _iosBeep;
  static Pointer<Void> Function()? _linuxDisplay;
  static void Function(Pointer<Void>)? _linuxBeep;

  static void ring() {
    try {
      if (Platform.isWindows && _ringWindows()) return;
      if (Platform.isAndroid) {
        // Fire and forget; a missing bridge must not surface as an error.
        _api.bell().catchError((_) {});
        return;
      }
      if (Platform.isMacOS && _ringMac()) return;
      if (Platform.isIOS && _ringIos()) return;
      if (Platform.isLinux && _ringLinux()) return;
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  // MessageBeep in user32 plays the standard system beep without an asset.
  static bool _ringWindows() {
    try {
      _windowsBeep ??= DynamicLibrary.open('user32.dll')
          .lookupFunction<Int32 Function(Uint32), int Function(int)>(
            'MessageBeep',
          );
      _windowsBeep!(0xFFFFFFFF);
      return true;
    } catch (_) {
      return false;
    }
  }

  // NSBeep is a plain C symbol in AppKit, which the runner links.
  static bool _ringMac() {
    try {
      _macBeep ??= DynamicLibrary.process()
          .lookupFunction<Void Function(), void Function()>('NSBeep');
      _macBeep!();
      return true;
    } catch (_) {
      return false;
    }
  }

  // AudioServicesPlaySystemSound from AudioToolbox; 1057 is a short system tone.
  static bool _ringIos() {
    try {
      _iosBeep ??=
          DynamicLibrary.open(
            '/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox',
          ).lookupFunction<Void Function(Uint32), void Function(int)>(
            'AudioServicesPlaySystemSound',
          );
      _iosBeep!(1057);
      return true;
    } catch (_) {
      return false;
    }
  }

  // gdk_display_beep on the default display; gdk is loaded by the GTK embedder.
  // Silent if the desktop has the system bell disabled, which is the user's
  // choice, not a failure.
  static bool _ringLinux() {
    try {
      final process = DynamicLibrary.process();
      _linuxDisplay ??= process
          .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
            'gdk_display_get_default',
          );
      _linuxBeep ??= process
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('gdk_display_beep');
      final display = _linuxDisplay!();
      if (display == nullptr) return false;
      _linuxBeep!(display);
      return true;
    } catch (_) {
      return false;
    }
  }
}
