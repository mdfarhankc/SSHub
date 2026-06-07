import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class SshConnectionException implements Exception {
  final String message;
  const SshConnectionException(this.message);
}

abstract interface class SshSessionHandle {
  Stream<String> get output;
  Future<void> get done;

  void write(String data);
  void resize(int width, int height, int pixelWidth, int pixelHeight);
  Future<void> close();
}

abstract interface class SshConnectionRepository {
  Future<SshSessionHandle> connect(
    SshServer server, {
    required String password,
  });
}
