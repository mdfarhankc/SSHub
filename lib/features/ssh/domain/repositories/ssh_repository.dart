import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

abstract interface class SshRepository {
  Future<List<SshServer>> getServers();
  Future<void> addServer(SshServer server);
  Future<void> updateServer(SshServer server);
  Future<void> deleteServer(String id);
  Future<void> clearAll();
}
