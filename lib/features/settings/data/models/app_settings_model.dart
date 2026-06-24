import 'package:sshub/features/settings/domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.terminalFontSize,
    super.terminalFontFamily,
    super.appLockEnabled,
    super.lockPasswordReveal,
    super.lockSnippetReveal,
    super.onboardingComplete,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      AppSettingsModel(
        themeMode:
            AppThemeMode.values.asNameMap()[json['themeMode']] ??
            AppThemeMode.system,
        terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14,
        terminalFontFamily:
            json['terminalFontFamily'] as String? ?? 'JetBrains Mono',
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        lockPasswordReveal: json['lockPasswordReveal'] as bool? ?? false,
        lockSnippetReveal: json['lockSnippetReveal'] as bool? ?? false,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'terminalFontSize': terminalFontSize,
    'terminalFontFamily': terminalFontFamily,
    'appLockEnabled': appLockEnabled,
    'lockPasswordReveal': lockPasswordReveal,
    'lockSnippetReveal': lockSnippetReveal,
    'onboardingComplete': onboardingComplete,
  };

  factory AppSettingsModel.fromEntity(AppSettings e) => AppSettingsModel(
    themeMode: e.themeMode,
    terminalFontSize: e.terminalFontSize,
    terminalFontFamily: e.terminalFontFamily,
    appLockEnabled: e.appLockEnabled,
    lockPasswordReveal: e.lockPasswordReveal,
    lockSnippetReveal: e.lockSnippetReveal,
    onboardingComplete: e.onboardingComplete,
  );
}
