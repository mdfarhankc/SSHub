import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/core/security/secure_platform.dart';
import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  SettingsCubit(this._repository, AppSettings initial)
    : super(SettingsState(settings: initial));

  Future<void> reload() async {
    try {
      emit(SettingsState(settings: await _repository.load()));
    } catch (e, s) {
      appLog("Failed to reload settings", e, s);
    }
  }

  void updateThemeMode(ThemeMode mode) =>
      _update(state.settings.copyWith(themeMode: mode));

  void toggleThemeMode() => updateThemeMode(
    state.settings.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark,
  );

  // Live while dragging: update the visible value without writing to disk on
  // every frame. updateTerminalFontSize persists once the drag ends.
  void previewTerminalFontSize(double size) => emit(
    SettingsState(settings: state.settings.copyWith(terminalFontSize: size)),
  );

  void updateTerminalFontSize(double size) =>
      _update(state.settings.copyWith(terminalFontSize: size));

  void updateTerminalFontFamily(String family) =>
      _update(state.settings.copyWith(terminalFontFamily: family));

  void updateTerminalColorScheme(String scheme) =>
      _update(state.settings.copyWith(terminalColorScheme: scheme));

  void updateTerminalScrollback(int lines) =>
      _update(state.settings.copyWith(terminalScrollback: lines));

  void updateCursorStyle(String style) =>
      _update(state.settings.copyWith(cursorStyle: style));

  void updateBellVisual(bool enabled) =>
      _update(state.settings.copyWith(bellVisual: enabled));

  void updateBellSound(bool enabled) =>
      _update(state.settings.copyWith(bellSound: enabled));

  void updateCopyOnSelect(bool enabled) =>
      _update(state.settings.copyWith(copyOnSelect: enabled));

  void updatePasteOnRightClick(bool enabled) =>
      _update(state.settings.copyWith(pasteOnRightClick: enabled));

  void updateReduceMotion(bool enabled) =>
      _update(state.settings.copyWith(reduceMotion: enabled));

  void updateCloseSessionOnBack(bool enabled) =>
      _update(state.settings.copyWith(closeSessionOnBack: enabled));

  void enableAppLock() =>
      _update(state.settings.copyWith(appLockEnabled: true));

  void disableAppLock() => _update(
    state.settings.copyWith(
      appLockEnabled: false,
      lockPasswordReveal: false,
      lockSnippetReveal: false,
    ),
  );

  void updateLockPasswordReveal(bool enabled) =>
      _update(state.settings.copyWith(lockPasswordReveal: enabled));

  void updateLockSnippetReveal(bool enabled) =>
      _update(state.settings.copyWith(lockSnippetReveal: enabled));

  void updateAutoLockMinutes(int minutes) =>
      _update(state.settings.copyWith(autoLockMinutes: minutes));

  void updateDefaultPort(int port) =>
      _update(state.settings.copyWith(defaultPort: port));

  void updateDefaultUsername(String username) =>
      _update(state.settings.copyWith(defaultUsername: username));

  void updateSftpShowHidden(bool enabled) =>
      _update(state.settings.copyWith(sftpShowHidden: enabled));

  void updateSftpGridView(bool enabled) =>
      _update(state.settings.copyWith(sftpGridView: enabled));

  void updateSftpReadOnly(bool enabled) =>
      _update(state.settings.copyWith(sftpReadOnly: enabled));

  void updateBlockScreenshots(bool enabled) {
    SecurePlatform.setBlockScreenshots(enabled);
    _update(state.settings.copyWith(blockScreenshots: enabled));
  }

  // Null resets to the platform default.
  void updateDownloadDirectory(String? path) => _update(
    state.settings.copyWith(
      downloadDirectory: path,
      clearDownloadDirectory: path == null,
    ),
  );

  // Passing the default binding (or null) drops the override so the action
  // falls back to its default.
  void updateShortcut(ShortcutAction action, KeyBinding? binding) {
    final overrides = {...state.settings.shortcutOverrides};
    if (binding == null || binding == shortcutDef(action).defaultBinding) {
      overrides.remove(action.name);
    } else {
      overrides[action.name] = binding.serialize();
    }
    _update(state.settings.copyWith(shortcutOverrides: overrides));
  }

  void resetShortcuts() =>
      _update(state.settings.copyWith(shortcutOverrides: const {}));

  Future<void> completeOnboarding() =>
      _update(state.settings.copyWith(onboardingComplete: true));

  Future<void> _update(AppSettings settings) async {
    emit(SettingsState(settings: settings));
    try {
      await _repository.save(settings);
    } catch (e, s) {
      appLog("Failed to save settings", e, s);
    }
  }
}
