import 'package:flutter/material.dart';

import 'package:sshub/core/security/secure_platform.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';

// Drops the debug-only Flutter Windows assertion on a bare Alt-down, which is
// harmless, and passes every other error through untouched.
void silenceHarmlessKeyAssertion() {
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('no keys are in keysPressed')) {
      return;
    }
    defaultOnError?.call(details);
  };
}

// Desktop has no secure default, so the stored value is applied at launch.
Future<void> applyScreenshotBlocking(AppSettings settings) async {
  if (SecurePlatform.canBlockScreenshots) {
    await SecurePlatform.setBlockScreenshots(settings.blockScreenshots);
  }
}
