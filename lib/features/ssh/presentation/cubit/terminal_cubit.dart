import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';

part 'terminal_state.dart';

class TerminalCubit extends Cubit<TerminalState> {
  final ConnectToServer _connectToServer;
  final SshServer server;
  SshSessionHandle? _handle;
  TerminalCubit(this._connectToServer, this.server)
    : super(const TerminalConnecting()) {
    _connect();
  }

  Future<void> _connect() async {
    try {
      final handle = await _connectToServer(server);
      _handle = handle;
      handle.done.whenComplete(() {
        if (!isClosed && _handle == handle) emit(const TerminalDisconnected());
      });
      emit(TerminalConnected(handle));
    } on SshConnectionException catch (e) {
      emit(TerminalFailure(e.message));
    } catch (e) {
      emit(TerminalFailure("Connection failed."));
    }
  }

  Future<void> reconnect() async {
    await _handle?.close();
    _handle = null;
    emit(const TerminalConnecting());
    await _connect();
  }

  @override
  Future<void> close() async {
    await _handle?.close();
    return super.close();
  }
}
