part of 'terminal_sessions_cubit.dart';

class TerminalSessionsState extends Equatable {
  final List<TerminalCubit> sessions;
  final int activeIndex;

  const TerminalSessionsState({this.sessions = const [], this.activeIndex = 0});

  bool get isEmpty => sessions.isEmpty;

  TerminalCubit? get active => activeIndex >= 0 && activeIndex < sessions.length
      ? sessions[activeIndex]
      : null;

  TerminalSessionsState copyWith({
    List<TerminalCubit>? sessions,
    int? activeIndex,
  }) => TerminalSessionsState(
    sessions: sessions ?? this.sessions,
    activeIndex: activeIndex ?? this.activeIndex,
  );

  @override
  List<Object?> get props => [sessions, activeIndex];
}
