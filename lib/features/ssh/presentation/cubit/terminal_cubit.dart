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
  String _lastError = "Connection failed.";

  static const _maxReconnectAttempts = 3;

  TerminalCubit(this._connectToServer, this.server)
    : super(const TerminalConnecting()) {
    _initialConnect();
  }

  Future<void> _initialConnect() async {
    if (!await _establish() && !isClosed) emit(TerminalFailure(_lastError));
  }

  // Opens a session and arms the disconnect handler. Returns true on success;
  // on failure it records the reason in [_lastError] rather than emitting, so
  // the caller decides whether to surface it or keep retrying.
  Future<bool> _establish() async {
    try {
      final handle = await _connectToServer(server);
      _handle = handle;
      handle.done.whenComplete(() {
        if (isClosed || _handle != handle) return;
        // A clean logout carries an exit code; a dropped link does not, so
        // only the latter triggers an automatic reconnect.
        if (handle.endedCleanly) {
          emit(const TerminalDisconnected());
        } else {
          _autoReconnect();
        }
      });
      emit(TerminalConnected(handle));
      return true;
    } on SshConnectionException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = "Connection failed.";
      return false;
    }
  }

  Future<void> _autoReconnect() async {
    for (var attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (isClosed) return;
      emit(
        TerminalReconnecting(
          attempt: attempt,
          maxAttempts: _maxReconnectAttempts,
        ),
      );
      await Future.delayed(Duration(seconds: 2 * attempt));
      if (isClosed) return;
      if (await _establish()) return;
    }
    if (!isClosed) emit(const TerminalDisconnected());
  }

  Future<void> reconnect() async {
    await _handle?.close();
    _handle = null;
    emit(const TerminalConnecting());
    if (!await _establish() && !isClosed) emit(TerminalFailure(_lastError));
  }

  @override
  Future<void> close() async {
    await _handle?.close();
    return super.close();
  }
}
