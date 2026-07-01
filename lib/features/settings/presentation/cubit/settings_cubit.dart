import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
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

  void updateThemeMode(AppThemeMode mode) =>
      _update(state.settings.copyWith(themeMode: mode));

  void updateTerminalFontSize(double size) =>
      _update(state.settings.copyWith(terminalFontSize: size));

  void updateTerminalFontFamily(String family) =>
      _update(state.settings.copyWith(terminalFontFamily: family));

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

  void completeOnboarding() =>
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
