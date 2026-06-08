import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == .dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: brightness,
    ).copyWith(surface: dark ? Colors.black : Colors.white);

    return ThemeData(
      colorScheme: scheme,
      fontFamily: "Inter",
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        errorMaxLines: 2,
      ),
    );
  }
}
