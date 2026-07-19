part of 'server_list_bloc.dart';

sealed class ServerListEvent {}

final class ServerListLoaded extends ServerListEvent {}

final class ServerReachabilityRequested extends ServerListEvent {}

final class ServerAdded extends ServerListEvent {
  final SshServer server;
  ServerAdded(this.server);
}

final class ServerUpdated extends ServerListEvent {
  final SshServer server;
  ServerUpdated(this.server);
}

final class ServerDeleted extends ServerListEvent {
  final String id;
  ServerDeleted(this.id);
}

// Stamps the connect time on the stored server. A tab holds the entity it was
// opened with, so writing that back would undo any edit made since.
final class ServerConnected extends ServerListEvent {
  final String id;
  ServerConnected(this.id);
}
