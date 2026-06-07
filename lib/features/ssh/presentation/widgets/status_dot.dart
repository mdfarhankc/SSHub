import 'package:flutter/material.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

class StatusDot extends StatelessWidget {
  const StatusDot(this.state, {super.key});
  final TerminalState state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      TerminalConnecting() => (Colors.amber, "Connecting"),
      TerminalConnected() => (Colors.green, "Connected"),
      TerminalDisconnected() => (Colors.red, "Disconnected"),
      TerminalFailure() => (Colors.red, "Failed"),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
