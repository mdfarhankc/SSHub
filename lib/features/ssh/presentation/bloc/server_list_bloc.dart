import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ssh_manager/features/ssh/domain/entities/ssh_server.dart';

part 'server_list_state.dart';
part 'server_list_event.dart';

class ServerListBloc extends Bloc<ServerListEvent, ServerListState> {
  ServerListBloc() : super(const ServerListState()) {
    on<ServerListLoaded>(_onLoaded);
    on<ServerAdded>(_onAdded);
    on<ServerDeleted>(_onDeleted);
  }

  Future<void> _onLoaded(
    ServerListLoaded event,
    Emitter<ServerListState> emit,
  ) async {
    emit(state.copyWith(status: ServerListStatus.loading));
    final dummy = <SshServer>[
      SshServer(
        id: "1",
        label: "Dummy 1",
        host: "192.34.954",
        username: "root",
      ),
      SshServer(
        id: "2",
        label: "Dummy 2",
        host: "192.34.654",
        username: "root",
      ),
    ];
    emit(state.copyWith(status: ServerListStatus.success, servers: dummy));
  }

  Future<void> _onAdded(
    ServerAdded event,
    Emitter<ServerListState> emit,
  ) async {
    emit(state.copyWith(servers: [...state.servers, event.server]));
  }

  Future<void> _onDeleted(
    ServerDeleted event,
    Emitter<ServerListState> emit,
  ) async {
    emit(
      state.copyWith(
        servers: state.servers.where((s) => s.id != event.id).toList(),
      ),
    );
  }
}
