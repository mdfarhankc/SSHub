import 'package:flutter/material.dart';

// Semantic colours outside the Material ColorScheme, exposed as a ThemeExtension.
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;

  const AppColors({required this.success, required this.warning});

  static const light = AppColors(
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
  );

  static const dark = AppColors(
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? success, Color? warning}) => AppColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
