import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class SshServerModel extends SshServer {
  const SshServerModel({
    required super.id,
    required super.label,
    required super.host,
    required super.username,
    super.password,
    super.privateKey,
    super.passphrase,
    super.port,
    super.description,
    super.authType,
    super.colorValue,
    super.lastConnectedAt,
  });

  factory SshServerModel.fromJson(Map<String, dynamic> json) => SshServerModel(
    id: json['id'] as String,
    label: json['label'] as String,
    host: json['host'] as String,
    username: json['username'] as String,
    password: json['password'] as String? ?? '',
    privateKey: json['privateKey'] as String? ?? '',
    passphrase: json['passphrase'] as String? ?? '',
    port: json['port'] as int? ?? 22,
    description: json['description'] as String? ?? '',
    authType:
        AuthType.values.asNameMap()[json['authType']] ?? AuthType.password,
    colorValue: json['colorValue'] as int?,
    lastConnectedAt: json['lastConnectedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastConnectedAt'] as int)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'host': host,
    'username': username,
    'password': password,
    'privateKey': privateKey,
    'passphrase': passphrase,
    'port': port,
    'description': description,
    'authType': authType.name,
    'colorValue': colorValue,
    'lastConnectedAt': lastConnectedAt?.millisecondsSinceEpoch,
  };

  factory SshServerModel.fromEntity(SshServer e) => SshServerModel(
    id: e.id,
    label: e.label,
    host: e.host,
    username: e.username,
    password: e.password,
    privateKey: e.privateKey,
    passphrase: e.passphrase,
    port: e.port,
    description: e.description,
    authType: e.authType,
    colorValue: e.colorValue,
    lastConnectedAt: e.lastConnectedAt,
  );
}
