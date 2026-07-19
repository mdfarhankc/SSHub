import 'package:sshub/features/ssh/data/datasources/server_datasource.dart';
import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

class SshRepositoryImpl implements SshRepository {
  final ServerDatasource _localDatasource;
  SshRepositoryImpl(this._localDatasource);

  // Every mutation loads the whole list and writes it back, and connects stamp
  // servers on their own, so overlapping writes would drop one.
  Future<void> _pending = Future.value();

  Future<void> _serialized(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.catchError((_) {});
    return result;
  }

  @override
  Future<List<SshServer>> getServers() => _localDatasource.load();

  @override
  Future<void> addServer(SshServer server) => _serialized(() async {
    final servers = await _localDatasource.load();
    await _localDatasource.save([
      ...servers,
      SshServerModel.fromEntity(server),
    ]);
  });

  @override
  Future<void> updateServer(SshServer server) => _serialized(() async {
    final servers = await _localDatasource.load();
    await _localDatasource.save([
      for (final s in servers)
        if (s.id == server.id) SshServerModel.fromEntity(server) else s,
    ]);
  });

  @override
  Future<void> deleteServer(String id) => _serialized(() async {
    final servers = await _localDatasource.load();
    await _localDatasource.save(servers.where((s) => s.id != id).toList());
  });

  @override
  Future<void> clearAll() => _serialized(_localDatasource.clear);
}
