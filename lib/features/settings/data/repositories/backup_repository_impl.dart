import 'dart:convert';

import 'package:sshub/core/backup/backup_crypto.dart';
import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/models/app_settings_model.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/ssh/data/datasources/secret_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

class BackupRepositoryImpl implements BackupRepository {
  // Keep in sync with the version in pubspec.yaml on each release.
  static const _appVersion = "1.0.0";

  final ServerLocalDatasource _serverDs;
  final SecretDatasource _secretDs;
  final SettingsLocalDatasource _settingsDs;

  const BackupRepositoryImpl(this._serverDs, this._secretDs, this._settingsDs);

  @override
  Future<String> export({
    required bool includeServers,
    required bool includeSettings,
    String? passphrase,
  }) async {
    final payload = <String, dynamic>{};

    if (includeServers) {
      final servers = await _serverDs.load();
      final list = <Map<String, dynamic>>[];
      for (final s in servers) {
        final json = s.toJson();
        final pw = await _secretDs.read(s.id);
        if (pw != null) json['password'] = pw;
        list.add(json);
      }
      payload['servers'] = list;
    }

    if (includeSettings) {
      payload['settings'] = (await _settingsDs.load()).toJson();
    }

    if (passphrase != null) {
      return BackupCrypto.encrypt(jsonEncode(payload), passphrase, _appVersion);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'sshub',
      'version': _appVersion,
      'encrypted': false,
      'data': payload,
    });
  }

  @override
  Future<int> import(String fileContent, String? passphrase) async {
    final Map<String, dynamic> data;
    if (BackupCrypto.isEncrypted(fileContent)) {
      if (passphrase == null) {
        throw const BackupException("This backup is encrypted.");
      }
      data =
          jsonDecode(await BackupCrypto.decrypt(fileContent, passphrase))
              as Map<String, dynamic>;
    } else {
      data =
          (jsonDecode(fileContent) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
    }

    var count = 0;
    if (data['servers'] != null) {
      final imported = [
        for (final e in data['servers'] as List) e as Map<String, dynamic>,
      ];
      final existing = await _serverDs.load();
      final byId = {for (final s in existing) s.id: s};
      for (final json in imported) {
        final model = SshServerModel.fromJson(json);
        byId[model.id] = model;
        final pw = json['password'];
        if (pw is String) await _secretDs.write(model.id, pw);
      }
      await _serverDs.save(byId.values.toList());
      count = imported.length;
    }

    if (data['settings'] != null) {
      await _settingsDs.save(
        AppSettingsModel.fromJson(data['settings'] as Map<String, dynamic>),
      );
    }
    return count;
  }
}
