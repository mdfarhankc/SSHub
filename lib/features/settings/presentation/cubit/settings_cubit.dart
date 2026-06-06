import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ssh_manager/features/settings/domain/entities/app_settings.dart';
import 'package:ssh_manager/features/settings/domain/repositories/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  SettingsCubit(this._repository) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
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

  void _update(AppSettings settings) {
    emit(SettingsState(settings: settings));
    _repository.save(settings);
  }
}
