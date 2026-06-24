abstract interface class BackupRepository {
  Future<String> export({
    required bool includeServers,
    required bool includeSettings,
    required bool includeSnippets,
    String? passphrase,
  });
  Future<int> import(String fileContent, String? passphrase);
}
