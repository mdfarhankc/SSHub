import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

abstract interface class SshRepository {
  Future<List<SshServer>> getServers();
  Future<void> addServer(SshServer server, {required String password});
  Future<void> updateServer(SshServer server, {required String? password});
  Future<void> deleteServer(String id);
  Future<String?> getPassword(String id);
  Future<void> clearAll();
}
