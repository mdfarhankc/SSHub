import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_path_bar.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_session_view.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_toolbar.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_session.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_session_view.dart';
import 'package:sshub/features/ssh/presentation/widgets/workspace_tab_bar.dart';

// Hosts every open tab, terminal or file browser. Sessions live in
// WorkspaceSessionsCubit, so they keep running while this page is popped; the
// page only decides which one is on screen and shows its toolbar.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  static const route = "/workspace";

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  // One key per terminal session so the app bar can drive its search and
  // snippet actions, which are view concerns rather than session state.
  final _keys = <TerminalCubit, GlobalKey<TerminalSessionViewState>>{};

  GlobalKey<TerminalSessionViewState> _keyFor(TerminalCubit session) =>
      _keys.putIfAbsent(session, () => GlobalKey<TerminalSessionViewState>());

  // Also bound here: a tab with no view yet cannot catch them.
  Map<ShortcutActivator, VoidCallback> _shortcutBindings(
    BuildContext context,
    Map<String, String> overrides,
  ) {
    final sessions = context.read<WorkspaceSessionsCubit>();
    return {
      // Tab cycling and Alt+number jumps stay fixed.
      ...shortcutBinding(LogicalKeyboardKey.tab, sessions.next),
      ...shortcutBinding(
        LogicalKeyboardKey.tab,
        sessions.previous,
        shift: true,
      ),
      ...buildShortcuts({
        ShortcutAction.newTab: () => ServerPickerSheet.openSession(context),
        ShortcutAction.closeTab: () =>
            sessions.closeSession(sessions.state.activeIndex),
      }, overrides),
      for (var i = 0; i < sessionDigitKeys.length; i++)
        SingleActivator(sessionDigitKeys[i], alt: true): () =>
            sessions.setActive(i),
    };
  }

  // Guards against an accidental back press ending several live connections.
  Future<bool> _confirmCloseAll(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Close all sessions?"),
        content: Text(
          "Going back closes all $count open sessions and ends their "
          "connections.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Close all"),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<WorkspaceSessionsCubit, WorkspaceSessionsState>(
      listenWhen: (_, current) => current.isEmpty,
      listener: (context, state) {
        // Closing the last tab leaves nothing to show, so fall back to Home.
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      builder: (context, state) {
        _keys.removeWhere(
          (cubit, _) => !state.sessions.any(
            (s) => s is TerminalWorkspaceSession && s.cubit == cubit,
          ),
        );
        final active = state.active;
        if (active == null) return const Scaffold(body: SizedBox.shrink());
        final activeIsFiles = active.kind == WorkspaceKind.files;

        // When enabled, the back button closes every session and leaves the
        // workspace, rather than leaving them running in tabs. The empty state
        // pops to Home via the isEmpty listener above.
        final closeOnBack = context.select<SettingsCubit, bool>(
          (c) => c.state.settings.closeSessionOnBack,
        );
        final overrides = context.select<SettingsCubit, Map<String, String>>(
          (c) => c.state.settings.shortcutOverrides,
        );

        return PopScope(
          canPop: !closeOnBack,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final sessions = context.read<WorkspaceSessionsCubit>();
            final count = sessions.state.sessions.length;
            if (count > 1 && !await _confirmCloseAll(context, count)) return;
            sessions.closeAll();
          },
          child: CallbackShortcuts(
            bindings: _shortcutBindings(context, overrides),
            // Yields focus once a terminal connects and asks for it.
            child: Focus(
              autofocus: true,
              child: Scaffold(
                appBar: AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.server.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        activeIsFiles
                            ? "Files"
                            : "${active.server.username}@${active.server.host}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: activeIsFiles ? null : AppTheme.mono,
                        ),
                      ),
                    ],
                  ),
                  actions: [_actionsFor(context, active)],
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(
                      WorkspaceTabBar.height +
                          (activeIsFiles ? SftpPathBar.height : 0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WorkspaceTabBar(
                          onNewTab: () =>
                              ServerPickerSheet.openSession(context),
                        ),
                        if (active is FileWorkspaceSession)
                          _PathBarFor(cubit: active.cubit),
                      ],
                    ),
                  ),
                ),
                // IndexedStack keeps every session mounted, so switching tabs
                // does not tear down a view or lose its scroll position.
                body: IndexedStack(
                  index: state.activeIndex,
                  sizing: StackFit.expand,
                  children: [
                    for (final session in state.sessions)
                      _viewFor(session, session == active),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _viewFor(WorkspaceSession session, bool isActive) {
    return switch (session) {
      TerminalWorkspaceSession(:final cubit) => TerminalSessionView(
        key: _keyFor(cubit),
        session: cubit,
        isActive: isActive,
      ),
      FileWorkspaceSession(:final cubit) => SftpSessionView(
        key: ValueKey(cubit),
        cubit: cubit,
      ),
    };
  }

  // The toolbar for the active tab: terminal search/snippets/status, or the
  // file browser's view and change actions.
  Widget _actionsFor(BuildContext context, WorkspaceSession active) {
    return switch (active) {
      TerminalWorkspaceSession(:final cubit) =>
        BlocBuilder<TerminalCubit, TerminalState>(
          bloc: cubit,
          builder: (context, terminalState) {
            final key = _keyFor(cubit);
            return Row(
              children: [
                if (terminalState is TerminalConnected) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Find (Ctrl+F)",
                    icon: const Icon(LucideIcons.search),
                    onPressed: () => key.currentState?.openSearch(),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Snippets (Ctrl+Shift+S)",
                    icon: const Icon(LucideIcons.zap),
                    onPressed: () => key.currentState?.showSnippets(),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Workflows (Ctrl+Shift+R)",
                    icon: const Icon(LucideIcons.workflow),
                    onPressed: () => key.currentState?.showWorkflows(),
                  ),
                ],
                Container(
                  margin: const EdgeInsets.only(left: 4, right: 8),
                  child: StatusDot(terminalState),
                ),
              ],
            );
          },
        ),
      FileWorkspaceSession(:final cubit) => BlocBuilder<SftpCubit, SftpState>(
        bloc: cubit,
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.min,
          children: state.status == SftpStatus.ready
              ? buildSftpActions(context, cubit, state)
              : const [],
        ),
      ),
    };
  }
}

// Reserves the path bar's height for a file tab and fills it once the session
// is ready, so switching folders does not resize the app bar.
class _PathBarFor extends StatelessWidget {
  final SftpCubit cubit;
  const _PathBarFor({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SftpCubit, SftpState>(
      bloc: cubit,
      builder: (context, state) => state.status == SftpStatus.ready
          ? SftpPathBar(state: state, cubit: cubit)
          : const SizedBox(height: SftpPathBar.height),
    );
  }
}
