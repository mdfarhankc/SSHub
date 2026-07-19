import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_session_view.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_tab_bar.dart';

// Hosts every open session. Sessions live in TerminalSessionsCubit, so they
// keep running while this page is popped; the page only decides which one is
// on screen.
class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  static const route = "/terminal";

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  // One key per session so the app bar can drive the visible session's search
  // and snippet actions, which are view concerns rather than session state.
  final _keys = <TerminalCubit, GlobalKey<TerminalSessionViewState>>{};

  GlobalKey<TerminalSessionViewState> _keyFor(TerminalCubit session) =>
      _keys.putIfAbsent(session, () => GlobalKey<TerminalSessionViewState>());

  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  // Also bound here: a tab with no terminal yet cannot catch them.
  Map<ShortcutActivator, VoidCallback> _shortcutBindings(BuildContext context) {
    final sessions = context.read<TerminalSessionsCubit>();
    return {
      ...shortcutBinding(LogicalKeyboardKey.tab, sessions.next),
      ...shortcutBinding(
        LogicalKeyboardKey.tab,
        sessions.previous,
        shift: true,
      ),
      ...shortcutBinding(
        LogicalKeyboardKey.keyT,
        () => ServerPickerSheet.openSession(context),
        shift: true,
      ),
      ...shortcutBinding(
        LogicalKeyboardKey.keyW,
        () => sessions.closeSession(sessions.state.activeIndex),
        shift: true,
      ),
      for (var i = 0; i < _digits.length; i++)
        SingleActivator(_digits[i], alt: true): () => sessions.setActive(i),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TerminalSessionsCubit, TerminalSessionsState>(
      listenWhen: (_, current) => current.isEmpty,
      listener: (context, state) {
        // Closing the last tab leaves nothing to show, so fall back to Home.
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      builder: (context, state) {
        _keys.removeWhere((session, _) => !state.sessions.contains(session));
        final active = state.active;
        if (active == null) return const Scaffold(body: SizedBox.shrink());
        final activeKey = _keyFor(active);
        final server = active.server;

        return CallbackShortcuts(
          bindings: _shortcutBindings(context),
          // Yields focus once a terminal connects and asks for it.
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${server.username}@${server.host}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: AppTheme.mono,
                      ),
                    ),
                  ],
                ),
                actions: [
                  BlocBuilder<TerminalCubit, TerminalState>(
                    bloc: active,
                    builder: (context, terminalState) => Row(
                      children: [
                        if (terminalState is TerminalConnected) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: "Find (Ctrl+F)",
                            icon: const Icon(LucideIcons.search),
                            onPressed: () =>
                                activeKey.currentState?.openSearch(),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: "Snippets (Ctrl+Shift+S)",
                            icon: const Icon(LucideIcons.zap),
                            onPressed: () =>
                                activeKey.currentState?.showSnippets(),
                          ),
                        ],
                        Container(
                          margin: const EdgeInsets.only(left: 4, right: 8),
                          child: StatusDot(terminalState),
                        ),
                      ],
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(TerminalTabBar.height),
                  child: TerminalTabBar(
                    onNewTab: () => ServerPickerSheet.openSession(context),
                  ),
                ),
              ),
              // IndexedStack keeps every session mounted, so switching tabs does
              // not tear down a terminal view or lose its scroll position.
              body: IndexedStack(
                index: state.activeIndex,
                sizing: StackFit.expand,
                children: [
                  for (final session in state.sessions)
                    TerminalSessionView(
                      key: _keyFor(session),
                      session: session,
                      isActive: session == active,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
