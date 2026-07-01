import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sshub/features/snippets/data/datasources/snippet_datasource.dart';
import 'package:sshub/features/snippets/data/models/snippet_model.dart';

class SnippetLocalDatasource implements SnippetDatasource {
  static const _namespace = "sshub_snippets";
  static const _key = "sshub_snippets";

  final FlutterSecureStorage _storage;
  const SnippetLocalDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _namespace),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _namespace),
    ),
  ]);

  @override
  Future<List<SnippetModel>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SnippetModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<SnippetModel> snippets) async {
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final s in snippets) s.toJson()]),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
