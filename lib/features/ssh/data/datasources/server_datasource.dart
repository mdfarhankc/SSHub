import 'package:sshub/features/ssh/data/models/ssh_server_model.dart';

abstract interface class ServerDatasource {
  Future<List<SshServerModel>> load();
  Future<void> save(List<SshServerModel> servers);
  Future<void> clear();
}
