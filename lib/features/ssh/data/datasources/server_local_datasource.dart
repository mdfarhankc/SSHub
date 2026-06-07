import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

class ServerLocalDatasource {
  const ServerLocalDatasource();
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File("${dir.path}${Platform.pathSeparator}servers.json");
  }

  Future<List<SshServerModel>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SshServerModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> save(List<SshServerModel> servers) async {
    final file = await _file();
    await file.writeAsString(jsonEncode([for (final s in servers) s.toJson()]));
  }
}
