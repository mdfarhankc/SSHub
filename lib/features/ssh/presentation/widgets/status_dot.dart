import 'package:flutter/material.dart';
import 'package:sshub/core/theme/app_colors.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

// Single source of truth for how a session state reads, shared by the status
// pill and the tab strip.
(Color, String) terminalStatusOf(BuildContext context, TerminalState state) {
  final theme = Theme.of(context);
  final colors = AppColors.of(context);
  return switch (state) {
    TerminalConnecting() => (colors.warning, "Connecting"),
    TerminalReconnecting() => (colors.warning, "Reconnecting"),
    TerminalConnected() => (colors.success, "Connected"),
    TerminalDisconnected() => (theme.colorScheme.error, "Disconnected"),
    TerminalFailure() => (theme.colorScheme.error, "Failed"),
  };
}

class StatusDot extends StatelessWidget {
  const StatusDot(this.state, {super.key});
  final TerminalState state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = terminalStatusOf(context, state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
