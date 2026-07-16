abstract interface class KnownHostsDatasource {
  // [type] is the host key algorithm. A server can offer one key per
  // algorithm, so a fingerprint is only meaningful alongside its type.
  Future<String?> fingerprintFor(String host, int port, String type);

  Future<void> remember(String host, int port, String type, String fingerprint);

  // Drops every remembered key for a host so the next connection trusts again.
  // The only way back from a rebuilt server, which legitimately gets new keys.
  Future<void> forget(String host, int port);
}
