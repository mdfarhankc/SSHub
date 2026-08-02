import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_colors.dart';

abstract final class AppTheme {
  static const String mono = "JetBrains Mono";
  static const double maxContentWidth = 1200;

  // Corner radius scale, smallest to largest.
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radius3xl = 28;

  // Getters, not cached finals, so theme edits show up on hot reload.
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

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
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E599),
      brightness: brightness,
    ).copyWith(error: const Color(0xFFE5484D), onError: Colors.white);

    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    );

    final base = ThemeData(
      colorScheme: scheme,
      // No fontFamily: use the platform's own UI font (Segoe UI on Windows,
      // SF on macOS/iOS, Roboto on Android), like the reference app.
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        brightness == Brightness.dark ? AppColors.dark : AppColors.light,
      ],
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
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const Icon(LucideIcons.chevronLeft),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
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
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius3xl),
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      // Plain knob, no checkmark, accent track when on.
      switchTheme: SwitchThemeData(
        thumbIcon: const WidgetStatePropertyAll(Icon(null)),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
      ),
      // Thin track, small thumb, no division ticks.
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        trackShape: const RoundedRectSliderTrackShape(),
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
