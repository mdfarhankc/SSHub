import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/sftp/domain/usecases/open_sftp_session.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_session.dart';

part 'workspace_sessions_state.dart';

// Owns every open tab, terminal or file browser. Sessions are created here
// rather than by a route so they survive tab switches and popping back to Home;
// that also makes closing them this cubit's job.
class WorkspaceSessionsCubit extends Cubit<WorkspaceSessionsState> {
  final ConnectToServer _connectToServer;
  final OpenSftpSession _openSftpSession;
  final SettingsCubit _settings;

  WorkspaceSessionsCubit(
    this._connectToServer,
    this._openSftpSession,
    this._settings,
  ) : super(const WorkspaceSessionsState());

  // Each session is a live connection with its own keepalive, so the tab count
  // is capped rather than left unbounded.
  static const maxSessions = 10;

  bool get isFull => state.sessions.length >= maxSessions;

  // Opens a terminal tab. [focusExisting] reuses an open terminal for the same
  // server, which is what tapping the server in the list means; the "+" button
  // passes false to stack a second one on purpose.
  void openTerminal(SshServer server, {bool focusExisting = true}) {
    if (focusExisting && _focus(server, WorkspaceKind.terminal)) {
      return;
    }
    if (isFull) return;
    final scrollback = _settings.state.settings.terminalScrollback;
    _add(
      TerminalWorkspaceSession(
        TerminalCubit(_connectToServer, server, scrollback: scrollback),
      ),
    );
  }

  // Opens a file browser tab, focusing an open one for the same server first.
  void openFiles(SshServer server, {bool focusExisting = true}) {
    if (focusExisting && _focus(server, WorkspaceKind.files)) return;
    if (isFull) return;
    _add(FileWorkspaceSession(SftpCubit(_openSftpSession, server, _settings)));
  }

  bool _focus(SshServer server, WorkspaceKind kind) {
    final index = state.sessions.indexWhere(
      (s) => s.kind == kind && s.server.id == server.id,
    );
    if (index == -1) return false;
    setActive(index);
    return true;
  }

  void _add(WorkspaceSession session) => emit(
    WorkspaceSessionsState(
      sessions: [...state.sessions, session],
      activeIndex: state.sessions.length,
    ),
  );

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
      WorkspaceSessionsState(
        sessions: sessions,
        activeIndex: active < 0 ? 0 : active,
      ),
    );
  }

  // Closes every session except the one at [keepIndex], which becomes active.
  void closeOthers(int keepIndex) {
    if (keepIndex < 0 || keepIndex >= state.sessions.length) return;
    final kept = state.sessions[keepIndex];
    for (final session in state.sessions) {
      if (session != kept) session.close();
    }
    emit(WorkspaceSessionsState(sessions: [kept]));
  }

  // Closes everything. The empty state pops the workspace back to Home.
  void closeAll() {
    for (final session in state.sessions) {
      session.close();
    }
    emit(const WorkspaceSessionsState());
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
