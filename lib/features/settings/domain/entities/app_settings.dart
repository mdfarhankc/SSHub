import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final double terminalFontSize;
  final String terminalFontFamily;
  final String terminalColorScheme;
  final int terminalScrollback;

  // Block, Bar or Underline.
  final String cursorStyle;

  // Flash the terminal when a program rings the bell.
  final bool bellVisual;

  // Play a native beep when a program rings the bell.
  final bool bellSound;

  // Copy a selection to the clipboard as soon as it is made.
  final bool copyOnSelect;

  // Right-click pastes instead of opening the context menu.
  final bool pasteOnRightClick;

  // Cut in-app animations for users who prefer less movement.
  final bool reduceMotion;

  // Leaving a terminal disconnects it instead of keeping the tab open.
  final bool closeSessionOnBack;

  final bool appLockEnabled;
  final bool lockPasswordReveal;
  final bool lockSnippetReveal;

  // Minutes of inactivity before the lock re-arms. 0 locks immediately on
  // leaving the app; -1 never auto-locks (only a cold start does).
  final int autoLockMinutes;

  final bool onboardingComplete;
  final bool sftpShowHidden;
  final bool sftpGridView;
  final bool sftpReadOnly;

  // Prefilled when adding a new server.
  final int defaultPort;
  final String defaultUsername;

  // Null uses the platform downloads folder.
  final String? downloadDirectory;

  // Android only.
  final bool blockScreenshots;

  // Keyboard shortcut overrides: action name to a serialized KeyBinding. Only
  // actions the user rebound appear here; the rest fall back to defaults.
  final Map<String, String> shortcutOverrides;

  const AppSettings({
    this.themeMode = .system,
    this.terminalFontSize = 14,
    this.terminalFontFamily = 'JetBrains Mono',
    this.terminalColorScheme = 'Default',
    this.terminalScrollback = 10000,
    this.cursorStyle = 'Block',
    this.bellVisual = false,
    this.bellSound = false,
    this.copyOnSelect = false,
    this.pasteOnRightClick = false,
    this.reduceMotion = false,
    this.closeSessionOnBack = true,
    this.appLockEnabled = false,
    this.lockPasswordReveal = false,
    this.lockSnippetReveal = false,
    this.autoLockMinutes = 0,
    this.onboardingComplete = false,
    this.sftpShowHidden = false,
    this.sftpGridView = false,
    this.sftpReadOnly = true,
    this.defaultPort = 22,
    this.defaultUsername = '',
    this.downloadDirectory,
    this.blockScreenshots = true,
    this.shortcutOverrides = const {},
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? terminalFontSize,
    String? terminalFontFamily,
    String? terminalColorScheme,
    int? terminalScrollback,
    String? cursorStyle,
    bool? bellVisual,
    bool? bellSound,
    bool? copyOnSelect,
    bool? pasteOnRightClick,
    bool? reduceMotion,
    bool? closeSessionOnBack,
    bool? appLockEnabled,
    bool? lockPasswordReveal,
    bool? lockSnippetReveal,
    int? autoLockMinutes,
    bool? onboardingComplete,
    bool? sftpShowHidden,
    bool? sftpGridView,
    bool? sftpReadOnly,
    int? defaultPort,
    String? defaultUsername,
    String? downloadDirectory,
    bool? blockScreenshots,
    Map<String, String>? shortcutOverrides,
    // null cannot express "reset to default".
    bool clearDownloadDirectory = false,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
    terminalColorScheme: terminalColorScheme ?? this.terminalColorScheme,
    terminalScrollback: terminalScrollback ?? this.terminalScrollback,
    cursorStyle: cursorStyle ?? this.cursorStyle,
    bellVisual: bellVisual ?? this.bellVisual,
    bellSound: bellSound ?? this.bellSound,
    copyOnSelect: copyOnSelect ?? this.copyOnSelect,
    pasteOnRightClick: pasteOnRightClick ?? this.pasteOnRightClick,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    closeSessionOnBack: closeSessionOnBack ?? this.closeSessionOnBack,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    lockPasswordReveal: lockPasswordReveal ?? this.lockPasswordReveal,
    lockSnippetReveal: lockSnippetReveal ?? this.lockSnippetReveal,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    sftpShowHidden: sftpShowHidden ?? this.sftpShowHidden,
    sftpGridView: sftpGridView ?? this.sftpGridView,
    sftpReadOnly: sftpReadOnly ?? this.sftpReadOnly,
    defaultPort: defaultPort ?? this.defaultPort,
    defaultUsername: defaultUsername ?? this.defaultUsername,
    downloadDirectory: clearDownloadDirectory
        ? null
        : (downloadDirectory ?? this.downloadDirectory),
    blockScreenshots: blockScreenshots ?? this.blockScreenshots,
    shortcutOverrides: shortcutOverrides ?? this.shortcutOverrides,
  );

  @override
  List<Object?> get props => [
    themeMode,
    terminalFontSize,
    terminalFontFamily,
    terminalColorScheme,
    terminalScrollback,
    cursorStyle,
    bellVisual,
    bellSound,
    copyOnSelect,
    pasteOnRightClick,
    reduceMotion,
    closeSessionOnBack,
    appLockEnabled,
    lockPasswordReveal,
    lockSnippetReveal,
    autoLockMinutes,
    onboardingComplete,
    sftpShowHidden,
    sftpGridView,
    sftpReadOnly,
    defaultPort,
    defaultUsername,
    downloadDirectory,
    blockScreenshots,
    shortcutOverrides,
  ];
}
