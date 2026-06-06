import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final double terminalFontSize;
  final String terminalFontFamily;

  const AppSettings({
    this.themeMode = .system,
    this.terminalFontSize = 14,
    this.terminalFontFamily = 'monospace',
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? terminalFontSize,
    String? terminalFontFamily,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
  );

  @override
  List<Object?> get props => [themeMode, terminalFontSize, terminalFontFamily];
}
