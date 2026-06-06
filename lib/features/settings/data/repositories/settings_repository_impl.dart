import 'package:ssh_manager/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:ssh_manager/features/settings/data/models/app_settings_model.dart';
import 'package:ssh_manager/features/settings/domain/entities/app_settings.dart';
import 'package:ssh_manager/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _localDatasource;
  const SettingsRepositoryImpl(this._localDatasource);

  @override
  Future<AppSettings> load() {
    return _localDatasource.load();
  }

  @override
  Future<void> save(AppSettings settings) {
    return _localDatasource.save(AppSettingsModel.fromEntity(settings));
  }
}
