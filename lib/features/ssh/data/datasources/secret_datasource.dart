import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretDatasource {
  static const _prefix = "ssh_password_";
  final FlutterSecureStorage _storage;
  const SecretDatasource([this._storage = const FlutterSecureStorage()]);

  Future<void> write(String id, String password) =>
      _storage.write(key: "$_prefix$id", value: password);
  Future<String?> read(String id) => _storage.read(key: "$_prefix$id");
  Future<void> delete(String id) => _storage.delete(key: "$_prefix$id");
}
