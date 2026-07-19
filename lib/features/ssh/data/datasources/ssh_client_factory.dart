import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

// Builds an authenticated SSH client. Shared by the shell and SFTP
// repositories so both go through the same host key verification and report
// the same failures.
class SshClientFactory {
  final KnownHostsDatasource _knownHosts;
  const SshClientFactory(this._knownHosts);

  Future<SSHClient> authenticated(
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
            _verifyHostKey(server, type, fingerprint),
      );

      // A server that accepts the socket then stalls during key exchange would
      // otherwise hang here for good.
      try {
        await client.authenticated.timeout(const Duration(seconds: 30));
      } on TimeoutException {
        client.close();
        throw const SshConnectionException(
          "The server accepted the connection but never finished signing in.",
        );
      }
      return client;
    } on SSHHostkeyError {
      throw const SshConnectionException(
        "The server's host key changed since the last connection. This could "
        "be a man-in-the-middle attack, so the connection was refused. If you "
        "rebuilt or reinstalled this server, use Forget host key from the "
        "server's menu, then connect again.",
      );
    } on SSHAuthFailError {
      throw SshConnectionException(
        server.authType == AuthType.key
            ? "The server rejected the key for ${server.username}."
            : "Authentication failed. Check the username and password.",
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
  // The fingerprint is whatever dartssh2 hands over, currently MD5.
  Future<bool> _verifyHostKey(
    SshServer server,
    String type,
    Uint8List fingerprint,
  ) async {
    final current = _hex(fingerprint);
    final known = await _knownHosts.fingerprintFor(
      server.host,
      server.port,
      type,
    );
    if (known == null) {
      await _knownHosts.remember(server.host, server.port, type, current);
      return true;
    }
    return known == current;
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
}
