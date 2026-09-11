import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sshub/features/workflows/data/datasources/workflow_datasource.dart';
import 'package:sshub/features/workflows/data/models/workflow_model.dart';

class WorkflowLocalDatasource implements WorkflowDatasource {
  static const _namespace = "sshub_workflows";
  static const _key = "sshub_workflows";

  final FlutterSecureStorage _storage;
  const WorkflowLocalDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _namespace),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _namespace),
    ),
  ]);

  @override
  Future<List<WorkflowModel>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        WorkflowModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<WorkflowModel> workflows) async {
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final w in workflows) w.toJson()]),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
