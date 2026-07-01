import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

// Debug-only diagnostics. No-op in release builds so nothing leaks to logs.
void appLog(String message, [Object? error, StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  developer.log(message, name: 'SSHub', error: error, stackTrace: stackTrace);
}
