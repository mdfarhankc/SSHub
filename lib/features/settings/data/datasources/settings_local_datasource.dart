import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/settings/data/datasources/settings_datasource.dart';
import 'package:sshub/features/settings/data/models/app_settings_model.dart';

class SettingsLocalDatasource implements SettingsDatasource {
  const SettingsLocalDatasource();
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File("${dir.path}${Platform.pathSeparator}settings.json");
  }

  @override
  Future<AppSettingsModel> load() async {
    final file = await _file();
    if (!await file.exists()) return const AppSettingsModel();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const AppSettingsModel();
    try {
      return AppSettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException catch (e) {
      appLog("Settings file is not valid JSON, using defaults", e);
      return const AppSettingsModel();
    }
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    final file = await _file();
    // Write to a temp file then rename so a crash mid-write can't corrupt
    // the settings file (rename is atomic on the same volume).
    final tmp = File("${file.path}.tmp");
    await tmp.writeAsString(jsonEncode(settings.toJson()), flush: true);
    await tmp.rename(file.path);
  }
}
