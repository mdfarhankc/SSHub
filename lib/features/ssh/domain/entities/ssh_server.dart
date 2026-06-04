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

  const SshServer({
    required this.id,
    required this.label,
    required this.host,
    required this.username,
    this.description = '',
    this.port = 22,
    this.authType = AuthType.password,
  });

  @override
  List<Object?> get props => [
    id,
    label,
    host,
    port,
    username,
    description,
    authType,
  ];
}
