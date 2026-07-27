// One remembered host key. [type] is null for keys stored before the algorithm
// was recorded.
class KnownHostEntry {
  final String host;
  final int port;
  final String? type;
  final String fingerprint;

  const KnownHostEntry({
    required this.host,
    required this.port,
    required this.type,
    required this.fingerprint,
  });
}

abstract interface class KnownHostsDatasource {
  // [type] is the host key algorithm. A server can offer one key per
  // algorithm, so a fingerprint is only meaningful alongside its type.
  Future<String?> fingerprintFor(String host, int port, String type);

  // Every remembered key, for showing and forgetting them one by one.
  Future<List<KnownHostEntry>> listAll();

  Future<void> remember(String host, int port, String type, String fingerprint);

  // Drops every remembered key for a host so the next connection trusts again.
  // The only way back from a rebuilt server, which legitimately gets new keys.
  Future<void> forget(String host, int port);

  // Drops every remembered key. Orphaned fingerprints would otherwise be
  // trusted again by a later server with the same host and port.
  Future<void> clear();
}
