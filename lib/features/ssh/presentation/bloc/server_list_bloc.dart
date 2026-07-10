import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/ssh/data/datasources/reachability_checker.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

part 'server_list_state.dart';
part 'server_list_event.dart';

class ServerListBloc extends Bloc<ServerListEvent, ServerListState> {
  final SshRepository _repository;
  final ReachabilityChecker _checker;

  ServerListBloc(
    this._repository, {
    this._checker = const ReachabilityChecker(),
  }) : super(const ServerListState()) {
    on<ServerListLoaded>(_onLoaded);
    on<ServerAdded>(_onAdded);
    on<ServerUpdated>(_onUpdated);
    on<ServerDeleted>(_onDeleted);
    on<ServerReachabilityRequested>(_onReachabilityRequested);
  }

  Future<void> _onReachabilityRequested(
    ServerReachabilityRequested event,
    Emitter<ServerListState> emit,
  ) async {
    final servers = state.servers;
    if (servers.isEmpty) return;
    var reachability = {for (final s in servers) s.id: Reachability.checking};
    emit(state.copyWith(reachability: reachability));
    await Future.wait(
      servers.map((s) async {
        final online = await _checker.isReachable(s.host, s.port);
        reachability = {
          ...reachability,
          s.id: online ? Reachability.online : Reachability.offline,
        };
        emit(state.copyWith(reachability: reachability));
      }),
    );
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
      await _repository.addServer(event.server);
      emit(state.copyWith(servers: [...state.servers, event.server]));
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not add server"));
    }
  }

  Future<void> _onUpdated(
    ServerUpdated event,
    Emitter<ServerListState> emit,
  ) async {
    try {
      await _repository.updateServer(event.server);
      emit(
        state.copyWith(
          servers: [
            for (final s in state.servers)
              if (s.id == event.server.id) event.server else s,
          ],
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not update server"));
    }
  }

  Future<void> _onDeleted(
    ServerDeleted event,
    Emitter<ServerListState> emit,
  ) async {
    try {
      await _repository.deleteServer(event.id);
      final reachability = {...state.reachability}..remove(event.id);
      emit(
        state.copyWith(
          servers: state.servers.where((s) => s.id != event.id).toList(),
          reachability: reachability,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not delete server"));
    }
  }
}
