import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class SshConnectionException implements Exception {
  final String message;
  const SshConnectionException(this.message);
}

abstract interface class SshSessionHandle {
  Stream<String> get output;
  Future<void> get done;

  // True when the remote shell exited on its own (carries an exit code); false
  // when [done] completed because the link dropped. Only valid after [done].
  bool get endedCleanly;

  void write(String data);
  void resize(int width, int height, int pixelWidth, int pixelHeight);
  Future<void> close();
}

abstract interface class SshConnectionRepository {
  Future<SshSessionHandle> connect(
    SshServer server, {
    String? password,
    String? privateKey,
    String? keyPassphrase,
  });
}
