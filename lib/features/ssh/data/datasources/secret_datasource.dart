import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretDatasource {
  static const _name = "sshub_servers";
  static const _prefix = "ssh_password_";
  final FlutterSecureStorage _storage;
  const SecretDatasource([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: _name),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(accountName: _name),
    ),
  ]);

  Future<void> write(String id, String password) =>
      _storage.write(key: "$_prefix$id", value: password);
  Future<String?> read(String id) => _storage.read(key: "$_prefix$id");
  Future<void> delete(String id) => _storage.delete(key: "$_prefix$id");
}
