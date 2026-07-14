import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

part 'terminal_sessions_state.dart';

// Owns every open terminal tab. Sessions are created here rather than by a
// route so they survive tab switches and popping back to Home; that also makes
// closing them this cubit's job.
class TerminalSessionsCubit extends Cubit<TerminalSessionsState> {
  final ConnectToServer _connectToServer;

  TerminalSessionsCubit(this._connectToServer)
    : super(const TerminalSessionsState());

  // Each session is a live SSH connection with its own keepalive, so the tab
  // count is capped rather than left unbounded.
  static const maxSessions = 10;

  bool get isFull => state.sessions.length >= maxSessions;

  // Always opens a new session, even if the server is already connected.
  void open(SshServer server) {
    if (isFull) return;
    emit(
      TerminalSessionsState(
        sessions: [...state.sessions, TerminalCubit(_connectToServer, server)],
        activeIndex: state.sessions.length,
      ),
    );
  }

  // Focuses an already open session for [server] instead of stacking a second
  // connection to the same host. Used from the server list, where a repeat tap
  // means "take me there", not "connect again".
  void openOrFocus(SshServer server) {
    final index = state.sessions.indexWhere((s) => s.server.id == server.id);
    if (index != -1) {
      setActive(index);
      return;
    }
    open(server);
  }

  void setActive(int index) {
    if (index < 0 || index >= state.sessions.length) return;
    emit(state.copyWith(activeIndex: index));
  }

  void closeSession(int index) {
    if (index < 0 || index >= state.sessions.length) return;
    final sessions = [...state.sessions];
    sessions.removeAt(index).close();

    var active = state.activeIndex;
    if (index < active) active -= 1;
    if (active > sessions.length - 1) active = sessions.length - 1;
    emit(
      TerminalSessionsState(
        sessions: sessions,
        activeIndex: active < 0 ? 0 : active,
      ),
    );
  }

  void next() {
    if (state.sessions.length < 2) return;
    setActive((state.activeIndex + 1) % state.sessions.length);
  }

  void previous() {
    if (state.sessions.length < 2) return;
    final length = state.sessions.length;
    setActive((state.activeIndex - 1 + length) % length);
  }

  @override
  Future<void> close() async {
    for (final session in state.sessions) {
      await session.close();
    }
    return super.close();
  }
}
