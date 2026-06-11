import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final double terminalFontSize;
  final String terminalFontFamily;
  final bool appLockEnabled;
  final bool lockPasswordReveal;

  const AppSettings({
    this.themeMode = .system,
    this.terminalFontSize = 14,
    this.terminalFontFamily = 'Cascadia Mono',
    this.appLockEnabled = false,
    this.lockPasswordReveal = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? terminalFontSize,
    String? terminalFontFamily,
    bool? appLockEnabled,
    bool? lockPasswordReveal,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    lockPasswordReveal: lockPasswordReveal ?? this.lockPasswordReveal,
  );

  @override
  List<Object?> get props => [
    themeMode,
    terminalFontSize,
    terminalFontFamily,
    appLockEnabled,
    lockPasswordReveal,
  ];
}
