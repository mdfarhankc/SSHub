import 'dart:convert';

import 'package:sshub/core/app_info.dart';
import 'package:sshub/core/backup/backup_crypto.dart';
import 'package:sshub/features/settings/data/datasources/settings_datasource.dart';
import 'package:sshub/features/settings/data/models/app_settings_model.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/snippets/data/datasources/snippet_datasource.dart';
import 'package:sshub/features/snippets/data/models/snippet_model.dart';
import 'package:sshub/features/ssh/data/datasources/server_datasource.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

class BackupRepositoryImpl implements BackupRepository {
  final ServerDatasource _serverDs;
  final SettingsDatasource _settingsDs;
  final SnippetDatasource _snippetDs;

  const BackupRepositoryImpl(this._serverDs, this._settingsDs, this._snippetDs);

  @override
  Future<String> export({
    required bool includeServers,
    required bool includeSettings,
    required bool includeSnippets,
    String? passphrase,
  }) async {
    final payload = <String, dynamic>{};

    if (includeServers) {
      final servers = await _serverDs.load();
      payload['servers'] = [for (final s in servers) s.toJson()];
    }

    if (includeSnippets) {
      final snippets = await _snippetDs.load();
      payload['snippets'] = [for (final s in snippets) s.toJson()];
    }

    if (includeSettings) {
      payload['settings'] = (await _settingsDs.load()).toJson();
    }

    if (passphrase != null) {
      return BackupCrypto.encrypt(jsonEncode(payload), passphrase, appVersion);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'sshub',
      'version': appVersion,
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
      }
      await _serverDs.save(byId.values.toList());
      count = imported.length;
    }

    if (data['snippets'] != null) {
      final imported = [
        for (final e in data['snippets'] as List) e as Map<String, dynamic>,
      ];
      final existing = await _snippetDs.load();
      final byId = {for (final s in existing) s.id: s};
      for (final json in imported) {
        final model = SnippetModel.fromJson(json);
        byId[model.id] = model;
      }
      await _snippetDs.save(byId.values.toList());
    }

    if (data['settings'] != null) {
      await _settingsDs.save(
        AppSettingsModel.fromJson(data['settings'] as Map<String, dynamic>),
      );
    }
    return count;
  }
}
