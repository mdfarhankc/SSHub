import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class SshServerModel extends SshServer {
  const SshServerModel({
    required super.id,
    required super.label,
    required super.host,
    required super.username,
    super.port,
    super.description,
    super.authType,
    super.colorValue,
  });

  factory SshServerModel.fromJson(Map<String, dynamic> json) => SshServerModel(
    id: json['id'] as String,
    label: json['label'] as String,
    host: json['host'] as String,
    username: json['username'] as String,
    port: json['port'] as int? ?? 22,
    description: json['description'] as String? ?? '',
    authType: AuthType.values.byName(json['authType'] as String),
    colorValue: json['colorValue'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'host': host,
    'username': username,
    'port': port,
    'description': description,
    'authType': authType.name,
    'colorValue': colorValue,
  };

  factory SshServerModel.fromEntity(SshServer e) => SshServerModel(
    id: e.id,
    label: e.label,
    host: e.host,
    username: e.username,
    port: e.port,
    description: e.description,
    authType: e.authType,
    colorValue: e.colorValue,
  );
}
