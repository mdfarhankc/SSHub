import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';

class KnownHostsLocalDatasource implements KnownHostsDatasource {
  static const _namespace = "sshub_known_hosts";
  static const _key = "sshub_known_hosts";

  final FlutterSecureStorage _storage;
  const KnownHostsLocalDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _namespace),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _namespace),
    ),
  ]);

  Future<Map<String, String>> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  @override
  Future<String?> fingerprintFor(String host, int port) async {
    final map = await _load();
    return map["$host:$port"];
  }

  @override
  Future<void> remember(String host, int port, String fingerprint) async {
    final map = await _load();
    map["$host:$port"] = fingerprint;
    await _storage.write(key: _key, value: jsonEncode(map));
  }
}
