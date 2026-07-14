import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';

class TerminalTabBar extends StatelessWidget {
  final VoidCallback onNewTab;
  const TerminalTabBar({super.key, required this.onNewTab});

  static const height = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<TerminalSessionsCubit, TerminalSessionsState>(
      builder: (context, state) {
        final sessions = context.read<TerminalSessionsCubit>();
        return Container(
          height: height,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outlineVariant),
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => _Tab(
                    session: state.sessions[index],
                    selected: index == state.activeIndex,
                    onTap: () => sessions.setActive(index),
                    onClose: () => sessions.closeSession(index),
                  ),
                ),
              ),
              IconButton(
                tooltip: sessions.isFull
                    ? "Tab limit reached"
                    : "New session (Ctrl+Shift+T)",
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: sessions.isFull ? null : onNewTab,
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final TerminalCubit session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Tab({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ServerColors.resolve(session.server.colorValue, scheme);

    return BlocBuilder<TerminalCubit, TerminalState>(
      bloc: session,
      builder: (context, state) {
        final (statusColor, statusLabel) = terminalStatusOf(context, state);
        return Center(
          child: Material(
            color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                height: 32,
                padding: const EdgeInsets.only(left: 10, right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: selected ? accent.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: statusLabel,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        session.server.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: selected
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: "Close (Ctrl+Shift+W)",
                      icon: const Icon(Icons.close_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      color: scheme.onSurfaceVariant,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
