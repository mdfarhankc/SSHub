part of 'server_list_bloc.dart';

enum ServerListStatus { initial, loading, success, failure }

enum Reachability { unknown, checking, online, offline }

class ServerListState extends Equatable {
  final ServerListStatus status;
  final List<SshServer> servers;
  final Map<String, Reachability> reachability;
  final String? errorMessage;
  const ServerListState({
    this.status = ServerListStatus.initial,
    this.servers = const [],
    this.reachability = const {},
    this.errorMessage,
  });

  ServerListState copyWith({
    ServerListStatus? status,
    List<SshServer>? servers,
    Map<String, Reachability>? reachability,
    String? errorMessage,
  }) => ServerListState(
    status: status ?? this.status,
    servers: servers ?? this.servers,
    reachability: reachability ?? this.reachability,
    // Errors are one-shot: any emit without errorMessage clears it.
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, servers, reachability, errorMessage];
}
