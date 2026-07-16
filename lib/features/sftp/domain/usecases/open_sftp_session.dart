import 'package:sshub/features/sftp/domain/repositories/sftp_repository.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

// Mirrors ConnectToServer: resolves the server's stored credentials and opens
// an SFTP channel with them.
class OpenSftpSession {
  final SftpRepository _sftpRepository;

  const OpenSftpSession(this._sftpRepository);

  Future<SftpSession> call(SshServer server) async {
    switch (server.authType) {
      case AuthType.password:
        if (server.password.isEmpty) {
          throw StateError("No stored password for ${server.label}");
        }
        return _sftpRepository.connect(server, password: server.password);
      case AuthType.key:
        if (server.privateKey.isEmpty) {
          throw StateError("No stored private key for ${server.label}");
        }
        return _sftpRepository.connect(
          server,
          privateKey: server.privateKey,
          keyPassphrase: server.passphrase.isEmpty ? null : server.passphrase,
        );
    }
  }
}
