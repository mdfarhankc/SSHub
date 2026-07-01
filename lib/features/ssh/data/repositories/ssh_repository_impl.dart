import 'package:sshub/features/ssh/data/datasources/server_datasource.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

class SshRepositoryImpl implements SshRepository {
  final ServerDatasource _localDatasource;
  const SshRepositoryImpl(this._localDatasource);

  @override
  Future<List<SshServer>> getServers() => _localDatasource.load();

  @override
  Future<void> addServer(SshServer server) async {
    final servers = await _localDatasource.load();
    await _localDatasource.save([
      ...servers,
      SshServerModel.fromEntity(server),
    ]);
  }

  @override
  Future<void> updateServer(SshServer server) async {
    final servers = await _localDatasource.load();
    await _localDatasource.save([
      for (final s in servers)
        if (s.id == server.id) SshServerModel.fromEntity(server) else s,
    ]);
  }

  @override
  Future<void> deleteServer(String id) async {
    final servers = await _localDatasource.load();
    await _localDatasource.save(servers.where((s) => s.id != id).toList());
  }

  @override
  Future<void> clearAll() => _localDatasource.clear();
}
