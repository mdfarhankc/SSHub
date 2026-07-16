import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

import 'package:sshub/features/ssh/data/datasources/ssh_client_factory.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

class SshConnectionRepositoryImpl implements SshConnectionRepository {
  final SshClientFactory _clients;
  const SshConnectionRepositoryImpl(this._clients);

  @override
  Future<SshSessionHandle> connect(
    SshServer server, {
    String? password,
    String? privateKey,
    String? keyPassphrase,
  }) async {
    final client = await _clients.authenticated(
      server,
      password: password,
      privateKey: privateKey,
      keyPassphrase: keyPassphrase,
    );
    try {
      final session = await client.shell(
        pty: const SSHPtyConfig(width: 80, height: 25),
      );
      return _DartSshSessionHandle(client, session);
    } catch (_) {
      // The client owns a socket and a keepalive timer, and the handle that
      // would have closed them was never built.
      client.close();
      rethrow;
    }
  }
}

class _DartSshSessionHandle implements SshSessionHandle {
  final SSHClient _client;
  final SSHSession _session;
  final _output = StreamController<String>();

  _DartSshSessionHandle(this._client, this._session) {
    // session.done already drives the disconnect state, so end output quietly.
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
  bool get endedCleanly => _session.exitCode != null;

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
