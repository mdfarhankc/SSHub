import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

class ConnectToServer {
  final SshRepository _sshRepository;
  final SshConnectionRepository _connectionRepository;

  const ConnectToServer(this._sshRepository, this._connectionRepository);

  Future<SshSessionHandle> call(SshServer server) async {
    final password = await _sshRepository.getPassword(server.id);
    if (password == null) {
      throw StateError("No stored password for ${server.label}");
    }
    return _connectionRepository.connect(server, password: password);
  }
}
