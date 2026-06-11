import 'package:sshub/features/settings/domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.terminalFontSize,
    super.terminalFontFamily,
    super.appLockEnabled,
    super.lockPasswordReveal,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      AppSettingsModel(
        themeMode:
            AppThemeMode.values.asNameMap()[json['themeMode']] ??
            AppThemeMode.system,
        terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14,
        terminalFontFamily:
            json['terminalFontFamily'] as String? ?? 'Cascadia Mono',
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        lockPasswordReveal: json['lockPasswordReveal'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'terminalFontSize': terminalFontSize,
    'terminalFontFamily': terminalFontFamily,
    'appLockEnabled': appLockEnabled,
    'lockPasswordReveal': lockPasswordReveal,
  };

  factory AppSettingsModel.fromEntity(AppSettings e) => AppSettingsModel(
    themeMode: e.themeMode,
    terminalFontSize: e.terminalFontSize,
    terminalFontFamily: e.terminalFontFamily,
    appLockEnabled: e.appLockEnabled,
    lockPasswordReveal: e.lockPasswordReveal,
  );
}
