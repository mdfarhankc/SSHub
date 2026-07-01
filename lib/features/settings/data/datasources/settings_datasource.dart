import 'package:sshub/features/settings/data/models/app_settings_model.dart';

abstract interface class SettingsDatasource {
  Future<AppSettingsModel> load();
  Future<void> save(AppSettingsModel settings);
}
