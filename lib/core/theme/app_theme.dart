import 'dart:ui';

import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Single source of truth for corner rounding across the app.
  static const double radius = 10;
  static final BorderRadius _borderRadius = BorderRadius.circular(radius);
  static final RoundedRectangleBorder _shape = RoundedRectangleBorder(
    borderRadius: _borderRadius,
  );

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == .dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 0, 26, 66),
      brightness: brightness,
    ).copyWith(surface: dark ? Colors.black : Colors.white);

    final buttonShape = WidgetStatePropertyAll(_shape);

    return ThemeData(
      colorScheme: scheme,
      fontFamily: "Inter",
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: _borderRadius),
        isDense: true,
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      cardTheme: CardThemeData(shape: _shape),
      dialogTheme: DialogThemeData(shape: _shape),
      popupMenuTheme: PopupMenuThemeData(shape: _shape),
      menuTheme: MenuThemeData(
        style: MenuStyle(shape: WidgetStatePropertyAll(_shape)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
    );
  }
}
