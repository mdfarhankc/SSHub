import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

class ServerLocalDatasource {
  static const _namespace = "sshub_servers";
  static const _key = "sshub_servers";
  static const _legacyPrefix = "ssh_password_";

  final FlutterSecureStorage _storage;
  const ServerLocalDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _namespace),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _namespace),
    ),
  ]);

  Future<List<SshServerModel>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return _migrateLegacy();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SshServerModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> save(List<SshServerModel> servers) async {
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final s in servers) s.toJson()]),
    );
  }

  Future<void> clear() => _storage.delete(key: _key);

  // One-time import from the previous split storage: a plaintext servers.json
  // file plus per-id passwords in secure storage. Merges them into the single
  // store, then removes the old artifacts.
  Future<List<SshServerModel>> _migrateLegacy() async {
    File file;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File("${dir.path}${Platform.pathSeparator}servers.json");
    } catch (_) {
      return [];
    }
    if (!await file.exists()) return [];

    final rawFile = await file.readAsString();
    if (rawFile.trim().isEmpty) return [];

    final list = jsonDecode(rawFile) as List<dynamic>;
    final migrated = <SshServerModel>[];
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final pw = await _storage.read(key: "$_legacyPrefix${map['id']}");
      if (pw != null) map['password'] = pw;
      migrated.add(SshServerModel.fromJson(map));
    }

    await save(migrated);
    try {
      await file.delete();
    } catch (_) {}
    for (final m in migrated) {
      await _storage.delete(key: "$_legacyPrefix${m.id}");
    }
    return migrated;
  }
}
