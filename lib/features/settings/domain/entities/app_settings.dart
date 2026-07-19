import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final double terminalFontSize;
  final String terminalFontFamily;
  final bool appLockEnabled;
  final bool lockPasswordReveal;
  final bool lockSnippetReveal;
  final bool onboardingComplete;
  final bool sftpShowHidden;
  final bool sftpGridView;
  final bool sftpReadOnly;

  // Null uses the platform downloads folder.
  final String? downloadDirectory;

  // Android only.
  final bool blockScreenshots;

  const AppSettings({
    this.themeMode = .system,
    this.terminalFontSize = 14,
    this.terminalFontFamily = 'JetBrains Mono',
    this.appLockEnabled = false,
    this.lockPasswordReveal = false,
    this.lockSnippetReveal = false,
    this.onboardingComplete = false,
    this.sftpShowHidden = false,
    this.sftpGridView = false,
    this.sftpReadOnly = true,
    this.downloadDirectory,
    this.blockScreenshots = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? terminalFontSize,
    String? terminalFontFamily,
    bool? appLockEnabled,
    bool? lockPasswordReveal,
    bool? lockSnippetReveal,
    bool? onboardingComplete,
    bool? sftpShowHidden,
    bool? sftpGridView,
    bool? sftpReadOnly,
    String? downloadDirectory,
    bool? blockScreenshots,
    // null cannot express "reset to default".
    bool clearDownloadDirectory = false,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    lockPasswordReveal: lockPasswordReveal ?? this.lockPasswordReveal,
    lockSnippetReveal: lockSnippetReveal ?? this.lockSnippetReveal,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    sftpShowHidden: sftpShowHidden ?? this.sftpShowHidden,
    sftpGridView: sftpGridView ?? this.sftpGridView,
    sftpReadOnly: sftpReadOnly ?? this.sftpReadOnly,
    downloadDirectory: clearDownloadDirectory
        ? null
        : (downloadDirectory ?? this.downloadDirectory),
    blockScreenshots: blockScreenshots ?? this.blockScreenshots,
  );

  @override
  List<Object?> get props => [
    themeMode,
    terminalFontSize,
    terminalFontFamily,
    appLockEnabled,
    lockPasswordReveal,
    lockSnippetReveal,
    onboardingComplete,
    sftpShowHidden,
    sftpGridView,
    sftpReadOnly,
    downloadDirectory,
    blockScreenshots,
  ];
}
