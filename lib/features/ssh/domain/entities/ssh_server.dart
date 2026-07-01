import 'package:equatable/equatable.dart';

enum AuthType { password, key }

class SshServer extends Equatable {
  final String id;
  final String label;
  final String host;
  final int port;
  final String username;
  final String password;
  final String privateKey;
  final String passphrase;
  final String description;
  final AuthType authType;
  final int? colorValue;
  final DateTime? lastConnectedAt;

  const SshServer({
    required this.id,
    required this.label,
    required this.host,
    required this.username,
    this.password = '',
    this.privateKey = '',
    this.passphrase = '',
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
    String? password,
    String? privateKey,
    String? passphrase,
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
    password: password ?? this.password,
    privateKey: privateKey ?? this.privateKey,
    passphrase: passphrase ?? this.passphrase,
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
    password,
    privateKey,
    passphrase,
    description,
    authType,
    colorValue,
    lastConnectedAt,
  ];
}
