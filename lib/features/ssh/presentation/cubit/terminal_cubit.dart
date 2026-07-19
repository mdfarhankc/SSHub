import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

part 'terminal_state.dart';

class TerminalCubit extends Cubit<TerminalState> {
  final ConnectToServer _connectToServer;
  final SshServer server;

  // The terminal and its selection controller belong to the session, not the
  // widget, so a tab keeps its scrollback while it sits in the background or
  // the terminal page is popped back to Home.
  final terminal = Terminal(maxLines: 10000);
  final terminalController = TerminalController();

  SshSessionHandle? _handle;
  StreamSubscription<String>? _outputSub;
  String _lastError = "Connection failed.";

  // isClosed only flips once close() has finished awaiting, so a connection
  // landing mid-dispose would still look live.
  bool _disposing = false;
  bool _stopReconnect = false;

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
      // Nothing else holds this handle, so a tab closed mid-connect would
      // leave the session open for the life of the app.
      if (_disposing || isClosed) {
        await handle.close();
        return false;
      }
      _handle = handle;
      _attach(handle);
      handle.done.whenComplete(() {
        if (isClosed || _handle != handle) return;
        _detach();
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

  void _attach(SshSessionHandle handle) {
    _outputSub = handle.output.listen(terminal.write);
    terminal.onOutput = handle.write;
    terminal.onResize = handle.resize;
  }

  void _detach() {
    _outputSub?.cancel();
    _outputSub = null;
    terminal.onOutput = null;
    terminal.onResize = null;
  }

  // Stops the retry loop between attempts, so a user who knows the server is
  // down does not have to wait it out.
  void stopReconnecting() => _stopReconnect = true;

  Future<void> _autoReconnect() async {
    // The shell has ended, but its client and keepalive timer live on until
    // the handle is closed.
    await _handle?.close();
    _handle = null;
    _stopReconnect = false;
    for (var attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (isClosed || _stopReconnect) break;
      emit(
        TerminalReconnecting(
          attempt: attempt,
          maxAttempts: _maxReconnectAttempts,
        ),
      );
      await Future.delayed(Duration(seconds: 2 * attempt));
      if (isClosed || _stopReconnect) break;
      if (await _establish()) return;
    }
    if (!isClosed) emit(const TerminalDisconnected());
  }

  Future<void> reconnect() async {
    // A manual attempt supersedes the loop, which would otherwise install a
    // second handle over this one.
    _stopReconnect = true;
    _detach();
    await _handle?.close();
    _handle = null;
    emit(const TerminalConnecting());
    if (!await _establish() && !isClosed) emit(TerminalFailure(_lastError));
  }

  @override
  Future<void> close() async {
    _disposing = true;
    _detach();
    terminalController.dispose();
    await _handle?.close();
    return super.close();
  }
}
