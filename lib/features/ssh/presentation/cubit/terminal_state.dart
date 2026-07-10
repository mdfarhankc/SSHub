part of 'terminal_cubit.dart';

sealed class TerminalState extends Equatable {
  const TerminalState();

  @override
  List<Object> get props => [];
}

final class TerminalConnecting extends TerminalState {
  const TerminalConnecting();
}

final class TerminalConnected extends TerminalState {
  final SshSessionHandle handle;
  const TerminalConnected(this.handle);

  @override
  List<Object> get props => [handle];
}

final class TerminalReconnecting extends TerminalState {
  final int attempt;
  final int maxAttempts;
  const TerminalReconnecting({
    required this.attempt,
    required this.maxAttempts,
  });

  @override
  List<Object> get props => [attempt, maxAttempts];
}

final class TerminalDisconnected extends TerminalState {
  const TerminalDisconnected();
}

final class TerminalFailure extends TerminalState {
  final String message;
  const TerminalFailure(this.message);

  @override
  List<Object> get props => [message];
}
