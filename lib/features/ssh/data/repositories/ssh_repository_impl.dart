import 'package:ssh_manager/features/ssh/data/datasources/secret_datasource.dart';
import 'package:ssh_manager/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:ssh_manager/features/ssh/data/models/ssh_server_model.dart';
import 'package:ssh_manager/features/ssh/domain/entities/ssh_server.dart';
import 'package:ssh_manager/features/ssh/domain/repositories/ssh_repository.dart';

class SshRepositoryImpl implements SshRepository {
  final ServerLocalDatasource _localDatasource;
  final SecretDatasource _secretDatasource;
  const SshRepositoryImpl(this._localDatasource, this._secretDatasource);

  @override
  Future<List<SshServer>> getServers() {
    return _localDatasource.load();
  }

  @override
  Future<void> addServer(SshServer server, {required String password}) async {
    final servers = await _localDatasource.load();
    await _localDatasource.save([
      ...servers,
      SshServerModel.fromEntity(server),
    ]);
    await _secretDatasource.write(server.id, password);
  }

  @override
  Future<void> deleteServer(String id) async {
    final servers = await _localDatasource.load();
    await _localDatasource.save(servers.where((s) => s.id != id).toList());
    await _secretDatasource.delete(id);
  }

  @override
  Future<String?> getPassword(String id) {
    return _secretDatasource.read(id);
  }
}
