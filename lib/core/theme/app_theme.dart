import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const double radius = 16;
  static const String mono = "JetBrains Mono";
  static const double maxContentWidth = 1200;

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static List<BoxShadow> cardShadow(
    Brightness brightness, {
    bool strong = false,
  }) {
    final dark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withValues(alpha: strong ? 0.45 : 0.3)
            : Colors.black.withValues(alpha: strong ? 0.1 : 0.05),
        blurRadius: strong ? 20 : 10,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: brightness,
        ).copyWith(
          surface: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          surfaceContainerLowest: dark
              ? const Color(0xFF0B1120)
              : const Color(0xFFFFFFFF),
          surfaceContainerLow: dark
              ? const Color(0xFF172033)
              : const Color(0xFFF8FAFC),
          surfaceContainer: dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          surfaceContainerHigh: dark
              ? const Color(0xFF263449)
              : const Color(0xFFE9EEF4),
          surfaceContainerHighest: dark
              ? const Color(0xFF2E3D55)
              : const Color(0xFFE2E8F0),
        );

    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: "Inter",
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: true,
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: scheme.outlineVariant,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    const figures = [FontFeature.tabularFigures()];
    TextStyle? tune(TextStyle? s, double spacing, double height) => s?.copyWith(
      letterSpacing: spacing,
      height: height,
      fontFeatures: figures,
    );

    return base.copyWith(
      displayLarge: tune(base.displayLarge, -1.5, 1.1),
      displayMedium: tune(base.displayMedium, -1.0, 1.1),
      displaySmall: tune(base.displaySmall, -0.5, 1.15),
      headlineLarge: tune(base.headlineLarge, -1.0, 1.15),
      headlineMedium: tune(base.headlineMedium, -0.8, 1.2),
      headlineSmall: tune(base.headlineSmall, -0.5, 1.25),
      titleLarge: tune(base.titleLarge, -0.4, 1.25),
      titleMedium: tune(base.titleMedium, -0.2, 1.3),
      titleSmall: tune(base.titleSmall, -0.1, 1.3),
      bodyLarge: tune(base.bodyLarge, 0, 1.45),
      bodyMedium: tune(base.bodyMedium, 0, 1.45),
      bodySmall: tune(base.bodySmall, 0.1, 1.4),
      labelLarge: tune(base.labelLarge, 0.1, 1.2),
      labelMedium: tune(base.labelMedium, 0.2, 1.2),
      labelSmall: tune(base.labelSmall, 0.3, 1.2),
    );
  }
}
