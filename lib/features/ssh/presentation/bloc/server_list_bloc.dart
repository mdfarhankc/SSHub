import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ssh_manager/features/ssh/domain/entities/ssh_server.dart';
import 'package:ssh_manager/features/ssh/domain/repositories/ssh_repository.dart';

part 'server_list_state.dart';
part 'server_list_event.dart';

class ServerListBloc extends Bloc<ServerListEvent, ServerListState> {
  final SshRepository _repository;

  ServerListBloc(this._repository) : super(const ServerListState()) {
    on<ServerListLoaded>(_onLoaded);
    on<ServerAdded>(_onAdded);
    on<ServerDeleted>(_onDeleted);
  }

  Future<void> _onLoaded(
    ServerListLoaded event,
    Emitter<ServerListState> emit,
  ) async {
    emit(state.copyWith(status: ServerListStatus.loading));
    try {
      final servers = await _repository.getServers();
      emit(state.copyWith(status: ServerListStatus.success, servers: servers));
    } catch (e) {
      emit(state.copyWith(status: ServerListStatus.failure));
    }
  }

  Future<void> _onAdded(
    ServerAdded event,
    Emitter<ServerListState> emit,
  ) async {
    try {
      await _repository.addServer(event.server, password: event.password);
      emit(state.copyWith(servers: [...state.servers, event.server]));
    } catch (e) {
      emit(state.copyWith(status: ServerListStatus.failure));
    }
  }

  Future<void> _onDeleted(
    ServerDeleted event,
    Emitter<ServerListState> emit,
  ) async {
    try {
      await _repository.deleteServer(event.id);
      emit(
        state.copyWith(
          servers: state.servers.where((s) => s.id != event.id).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ServerListStatus.failure));
    }
  }
}
