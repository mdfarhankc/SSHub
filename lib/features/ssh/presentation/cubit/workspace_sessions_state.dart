part of 'workspace_sessions_cubit.dart';

class WorkspaceSessionsState extends Equatable {
  final List<WorkspaceSession> sessions;
  final int activeIndex;

  const WorkspaceSessionsState({
    this.sessions = const [],
    this.activeIndex = 0,
  });

  bool get isEmpty => sessions.isEmpty;

  WorkspaceSession? get active =>
      activeIndex >= 0 && activeIndex < sessions.length
      ? sessions[activeIndex]
      : null;

  WorkspaceSessionsState copyWith({
    List<WorkspaceSession>? sessions,
    int? activeIndex,
  }) => WorkspaceSessionsState(
    sessions: sessions ?? this.sessions,
    activeIndex: activeIndex ?? this.activeIndex,
  );

  @override
  List<Object?> get props => [sessions, activeIndex];
}
