import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

class SshConnectionRepositoryImpl implements SshConnectionRepository {
  const SshConnectionRepositoryImpl();

  @override
  Future<SshSessionHandle> connect(
    SshServer server, {
    required String password,
  }) async {
    try {
      final socket = await SSHSocket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 10),
      );
      final client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => password,
      );

      await client.authenticated;

      final session = await client.shell(
        pty: const SSHPtyConfig(width: 80, height: 25),
      );
      return _DartSshSessionHandle(client, session);
    } on SSHAuthFailError {
      throw const SshConnectionException(
        "Authentication failed. Check the username and password.",
      );
    } on SocketException {
      throw SshConnectionException(
        "Could not reach ${server.host}:${server.port}.",
      );
    } on TimeoutException {
      throw SshConnectionException("Connection to ${server.host} timed out.");
    }
  }
}

class _DartSshSessionHandle implements SshSessionHandle {
  final SSHClient _client;
  final SSHSession _session;
  final _output = StreamController<String>();

  _DartSshSessionHandle(this._client, this._session) {
    // Stream errors carry no extra information for the UI (session.done
    // already drives the disconnect state), so end the output quietly.
    _session.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(
          _output.add,
          onDone: _output.close,
          onError: (_) => _output.close(),
        );
    _session.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(_output.add, onError: (_) {});
  }

  @override
  Stream<String> get output => _output.stream;

  @override
  Future<void> get done => _session.done;

  @override
  void write(String data) => _session.write(utf8.encode(data));

  @override
  void resize(int width, int height, int pixelWidth, int pixelHeight) =>
      _session.resizeTerminal(width, height, pixelWidth, pixelHeight);

  @override
  Future<void> close() async {
    _session.close();
    _client.close();
  }
}
