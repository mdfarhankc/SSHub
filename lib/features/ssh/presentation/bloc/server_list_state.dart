part of 'server_list_bloc.dart';

enum ServerListStatus { initial, loading, success, failure }

class ServerListState extends Equatable {
  final ServerListStatus status;
  final List<SshServer> servers;
  final String? errorMessage;
  const ServerListState({
    this.status = ServerListStatus.initial,
    this.servers = const [],
    this.errorMessage,
  });

  ServerListState copyWith({
    ServerListStatus? status,
    List<SshServer>? servers,
    String? errorMessage,
  }) => ServerListState(
    status: status ?? this.status,
    servers: servers ?? this.servers,
    // No fallback on purpose: errors are one-shot. Any emit that doesn't
    // explicitly pass errorMessage clears it.
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, servers, errorMessage];
}
