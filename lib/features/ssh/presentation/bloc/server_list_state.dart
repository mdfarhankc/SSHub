part of 'server_list_bloc.dart';

enum ServerListStatus { initial, loading, success, failure }

class ServerListState extends Equatable {
  final ServerListStatus status;
  final List<SshServer> servers;
  const ServerListState({
    this.status = ServerListStatus.initial,
    this.servers = const [],
  });

  ServerListState copyWith({
    ServerListStatus? status,
    List<SshServer>? servers,
  }) => ServerListState(
    status: status ?? this.status,
    servers: servers ?? this.servers,
  );

  @override
  List<Object?> get props => [status, servers];
}
