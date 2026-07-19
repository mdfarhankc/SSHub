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
  Future<String?> fingerprintFor(String host, int port, String type) async {
    final map = await _load();
    final known = map[_entryFor(host, port, type)];
    if (known != null) return known;
    // Keys remembered before the type was recorded. Still honoured, or an
    // update would silently trust every server again.
    return map[_legacyEntryFor(host, port)];
  }

  @override
  Future<void> remember(
    String host,
    int port,
    String type,
    String fingerprint,
  ) async {
    final map = await _load();
    map[_entryFor(host, port, type)] = fingerprint;
    await _storage.write(key: _key, value: jsonEncode(map));
  }

  @override
  Future<void> forget(String host, int port) async {
    final map = await _load();
    final prefix = "$host:$port:";
    map.removeWhere(
      (key, _) => key == _legacyEntryFor(host, port) || key.startsWith(prefix),
    );
    await _storage.write(key: _key, value: jsonEncode(map));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);

  static String _entryFor(String host, int port, String type) =>
      "$host:$port:$type";

  static String _legacyEntryFor(String host, int port) => "$host:$port";
}
