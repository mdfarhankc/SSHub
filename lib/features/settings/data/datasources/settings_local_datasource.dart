import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ssh_manager/features/settings/data/models/app_settings_model.dart';

class SettingsLocalDatasource {
  const SettingsLocalDatasource();
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File("${dir.path}${Platform.pathSeparator}settings.json");
  }

  Future<AppSettingsModel> load() async {
    final file = await _file();
    if (!await file.exists()) return const AppSettingsModel();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const AppSettingsModel();
    try {
      return AppSettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettingsModel();
    }
  }

  Future<void> save(AppSettingsModel settings) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(settings.toJson()));
  }
}
