import 'package:flutter/material.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

class StatusDot extends StatelessWidget {
  const StatusDot(this.state, {super.key});
  final TerminalState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = switch (state) {
      TerminalConnecting() => (Colors.amber, "Connecting"),
      TerminalConnected() => (const Color(0xFF22C55E), "Connected"),
      TerminalDisconnected() => (theme.colorScheme.error, "Disconnected"),
      TerminalFailure() => (theme.colorScheme.error, "Failed"),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
