part of 'settings_cubit.dart';

final class SettingsState extends Equatable {
  final AppSettings settings;
  const SettingsState({this.settings = const AppSettings()});

  @override
  List<Object> get props => [settings];
}
