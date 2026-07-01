abstract interface class KnownHostsDatasource {
  Future<String?> fingerprintFor(String host, int port);
  Future<void> remember(String host, int port, String fingerprint);
}
