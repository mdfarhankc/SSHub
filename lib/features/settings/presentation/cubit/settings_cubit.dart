import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    } catch (_) {}
  }

  void updateThemeMode(AppThemeMode mode) =>
      _update(state.settings.copyWith(themeMode: mode));

  void updateTerminalFontSize(double size) =>
      _update(state.settings.copyWith(terminalFontSize: size));

  void updateTerminalFontFamily(String family) =>
      _update(state.settings.copyWith(terminalFontFamily: family));

  void updateAppLock(bool enabled) =>
      _update(state.settings.copyWith(appLockEnabled: enabled));

  void updateLockPasswordReveal(bool enabled) =>
      _update(state.settings.copyWith(lockPasswordReveal: enabled));

  Future<void> _update(AppSettings settings) async {
    emit(SettingsState(settings: settings));
    try {
      await _repository.save(settings);
    } catch (_) {}
  }
}
