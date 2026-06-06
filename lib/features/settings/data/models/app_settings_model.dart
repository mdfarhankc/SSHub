import 'package:ssh_manager/features/settings/domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.terminalFontSize,
    super.terminalFontFamily,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      AppSettingsModel(
        themeMode:
            AppThemeMode.values.asNameMap()[json['themeMode']] ??
            AppThemeMode.system,
        terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14,
        terminalFontFamily:
            json['terminalFontFamily'] as String? ?? 'monospace',
      );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'terminalFontSize': terminalFontSize,
    'terminalFontFamily': terminalFontFamily,
  };

  factory AppSettingsModel.fromEntity(AppSettings e) => AppSettingsModel(
    themeMode: e.themeMode,
    terminalFontSize: e.terminalFontSize,
    terminalFontFamily: e.terminalFontFamily,
  );
}
