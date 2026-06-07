part of 'server_list_bloc.dart';

sealed class ServerListEvent {}

final class ServerListLoaded extends ServerListEvent {}

final class ServerAdded extends ServerListEvent {
  final SshServer server;
  final String password;
  ServerAdded(this.server, this.password);
}

final class ServerUpdated extends ServerListEvent {
  final SshServer server;
  final String? password;
  ServerUpdated(this.server, this.password);
}

final class ServerDeleted extends ServerListEvent {
  final String id;
  ServerDeleted(this.id);
}
