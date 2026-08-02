import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sshub/features/ssh/data/datasources/server_datasource.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

class ServerLocalDatasource implements ServerDatasource {
  static const _namespace = "sshub_servers";
  static const _key = "sshub_servers";

  final FlutterSecureStorage _storage;

  const ServerLocalDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _namespace),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _namespace),
      iOptions: IOSOptions(accountName: _namespace),
    ),
  ]);

  @override
  Future<List<SshServerModel>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SshServerModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<SshServerModel> servers) async {
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final s in servers) s.toJson()]),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
