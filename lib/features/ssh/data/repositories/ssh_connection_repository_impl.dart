import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

class SshConnectionRepositoryImpl implements SshConnectionRepository {
  final KnownHostsDatasource _knownHosts;
  const SshConnectionRepositoryImpl(this._knownHosts);

  @override
  Future<SshSessionHandle> connect(
    SshServer server, {
    String? password,
    String? privateKey,
    String? keyPassphrase,
  }) async {
    final identities = privateKey == null || privateKey.isEmpty
        ? null
        : _identities(privateKey, keyPassphrase);
    try {
      final socket = await SSHSocket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 10),
      );
      final client = SSHClient(
        socket,
        username: server.username,
        identities: identities,
        onPasswordRequest: password == null ? null : () => password,
        onVerifyHostKey: (type, fingerprint) =>
            _verifyHostKey(server, fingerprint),
      );

      await client.authenticated;

      final session = await client.shell(
        pty: const SSHPtyConfig(width: 80, height: 25),
      );
      return _DartSshSessionHandle(client, session);
    } on SSHHostkeyError {
      throw const SshConnectionException(
        "The server's host key changed since the last connection. This could "
        "be a man-in-the-middle attack, so the connection was refused.",
      );
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

  List<SSHKeyPair> _identities(String privateKey, String? passphrase) {
    try {
      return SSHKeyPair.fromPem(privateKey, passphrase);
    } on SSHKeyDecryptError {
      throw const SshConnectionException(
        "Wrong passphrase for the private key.",
      );
    } catch (_) {
      throw const SshConnectionException("Invalid or unsupported private key.");
    }
  }

  // Trust on first use: store the fingerprint, then refuse if it ever changes.
  Future<bool> _verifyHostKey(SshServer server, Uint8List fingerprint) async {
    final current = _hex(fingerprint);
    final known = await _knownHosts.fingerprintFor(server.host, server.port);
    if (known == null) {
      await _knownHosts.remember(server.host, server.port, current);
      return true;
    }
    return known == current;
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
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
