import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

        return Scaffold(
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
                        tooltip: "Find (Ctrl+F)",
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () =>
                            activeKey.currentState?.openSearch(),
                      ),
                      IconButton(
                        tooltip: "Snippets (Ctrl+Shift+S)",
                        icon: const Icon(Icons.bolt_outlined),
                        onPressed: () =>
                            activeKey.currentState?.showSnippets(),
                      ),
                    ],
                    Container(
                      margin: const EdgeInsets.only(right: 8),
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
        );
      },
    );
  }
}
