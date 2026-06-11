import 'package:equatable/equatable.dart';

enum AuthType { password, key }

class SshServer extends Equatable {
  final String id;
  final String label;
  final String host;
  final int port;
  final String username;
  final String description;
  final AuthType authType;
  final int? colorValue;
  final DateTime? lastConnectedAt;

  const SshServer({
    required this.id,
    required this.label,
    required this.host,
    required this.username,
    this.description = '',
    this.port = 22,
    this.authType = AuthType.password,
    this.colorValue,
    this.lastConnectedAt,
  });

  SshServer copyWith({
    String? label,
    String? host,
    int? port,
    String? username,
    String? description,
    AuthType? authType,
    int? colorValue,
    DateTime? lastConnectedAt,
  }) => SshServer(
    id: id,
    label: label ?? this.label,
    host: host ?? this.host,
    port: port ?? this.port,
    username: username ?? this.username,
    description: description ?? this.description,
    authType: authType ?? this.authType,
    colorValue: colorValue ?? this.colorValue,
    lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
  );

  @override
  List<Object?> get props => [
    id,
    label,
    host,
    port,
    username,
    description,
    authType,
    colorValue,
    lastConnectedAt,
  ];
}
