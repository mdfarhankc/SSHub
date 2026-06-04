import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: .all(.circular(10))),
        isDense: true,
        errorMaxLines: 2,
      ),
    );
  }
}
