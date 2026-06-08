abstract interface class BackupRepository {
  Future<String> export({
    required bool includeServers,
    required bool includeSettings,
    String? passphrase,
  });
  Future<int> import(String fileContent, String? passphrase);
}
