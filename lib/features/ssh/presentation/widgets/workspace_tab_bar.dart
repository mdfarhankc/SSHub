import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_status.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_session.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';

class WorkspaceTabBar extends StatelessWidget {
  final VoidCallback onNewTab;
  const WorkspaceTabBar({super.key, required this.onNewTab});

  static const height = 44.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<WorkspaceSessionsCubit, WorkspaceSessionsState>(
      builder: (context, state) {
        final sessions = context.read<WorkspaceSessionsCubit>();
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
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => _Tab(
                    session: state.sessions[index],
                    index: index,
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
                icon: const Icon(LucideIcons.plus, size: 20),
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
  final WorkspaceSession session;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Tab({
    required this.session,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Each tab tracks its own session's status through the matching cubit.
    return switch (session) {
      TerminalWorkspaceSession(:final cubit) =>
        BlocBuilder<TerminalCubit, TerminalState>(
          bloc: cubit,
          builder: (context, state) {
            final (color, label) = terminalStatusOf(context, state);
            return _TabChrome(
              session: session,
              index: index,
              selected: selected,
              typeIcon: LucideIcons.terminal,
              statusColor: color,
              statusLabel: label,
              onTap: onTap,
              onClose: onClose,
            );
          },
        ),
      FileWorkspaceSession(:final cubit) => BlocBuilder<SftpCubit, SftpState>(
        bloc: cubit,
        builder: (context, state) {
          final (color, label) = sftpStatusOf(context, state);
          return _TabChrome(
            session: session,
            index: index,
            selected: selected,
            typeIcon: LucideIcons.folder,
            statusColor: color,
            statusLabel: label,
            onTap: onTap,
            onClose: onClose,
          );
        },
      ),
    };
  }
}

enum _TabAction { duplicate, close, closeOthers, closeAll }

// Opens another session to the same server, matching this tab's kind.
void _duplicate(WorkspaceSessionsCubit sessions, WorkspaceSession session) {
  switch (session.kind) {
    case WorkspaceKind.terminal:
      sessions.openTerminal(session.server, focusExisting: false);
    case WorkspaceKind.files:
      sessions.openFiles(session.server, focusExisting: false);
  }
}

class _TabChrome extends StatelessWidget {
  final WorkspaceSession session;
  final int index;
  final bool selected;
  final IconData typeIcon;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabChrome({
    required this.session,
    required this.index,
    required this.selected,
    required this.typeIcon,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    required this.onClose,
  });

  // Right-click on desktop, long-press on touch: both land on the same menu.
  Future<void> _showMenu(BuildContext context, Offset globalPos) async {
    final sessions = context.read<WorkspaceSessionsCubit>();
    final onlyTab = sessions.state.sessions.length <= 1;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<_TabAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: _TabAction.duplicate,
          child: _MenuRow(icon: LucideIcons.copyPlus, label: "Duplicate"),
        ),
        const PopupMenuItem(
          value: _TabAction.close,
          child: _MenuRow(icon: LucideIcons.x, label: "Close"),
        ),
        PopupMenuItem(
          value: _TabAction.closeOthers,
          enabled: !onlyTab,
          child: const _MenuRow(icon: LucideIcons.listX, label: "Close others"),
        ),
        const PopupMenuItem(
          value: _TabAction.closeAll,
          child: _MenuRow(icon: LucideIcons.xCircle, label: "Close all"),
        ),
      ],
    );
    switch (choice) {
      case _TabAction.duplicate:
        _duplicate(sessions, session);
      case _TabAction.close:
        sessions.closeSession(index);
      case _TabAction.closeOthers:
        sessions.closeOthers(index);
      case _TabAction.closeAll:
        sessions.closeAll();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ServerColors.resolve(session.server.colorValue, scheme);

    return Center(
      child: GestureDetector(
        onSecondaryTapDown: (d) => _showMenu(context, d.globalPosition),
        onLongPressStart: (d) => _showMenu(context, d.globalPosition),
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
                  color: selected
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent,
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
                  Icon(typeIcon, size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
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
                    icon: const Icon(LucideIcons.x, size: 14),
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
      ),
    );
  }
}

// One row of the tab context menu: an icon and its label.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)],
    );
  }
}
