import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

class ConnectToServer {
  final SshConnectionRepository _connectionRepository;

  const ConnectToServer(this._connectionRepository);

  Future<SshSessionHandle> call(SshServer server) async {
    switch (server.authType) {
      case AuthType.password:
        if (server.password.isEmpty) {
          throw StateError("No stored password for ${server.label}");
        }
        return _connectionRepository.connect(server, password: server.password);
      case AuthType.key:
        if (server.privateKey.isEmpty) {
          throw StateError("No stored private key for ${server.label}");
        }
        return _connectionRepository.connect(
          server,
          privateKey: server.privateKey,
          keyPassphrase: server.passphrase.isEmpty ? null : server.passphrase,
        );
    }
  }
}
