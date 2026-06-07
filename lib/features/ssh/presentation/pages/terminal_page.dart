import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/theme/app_terminal_theme.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

class TerminalPage extends StatefulWidget {
  final SshServer server;
  const TerminalPage({super.key, required this.server});

  static const route = "/terminal";

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final terminal = Terminal(maxLines: 10000);

  void _attach(SshSessionHandle handle) {
    handle.output.listen(terminal.write);
    terminal.onOutput = handle.write;
    terminal.onResize = handle.resize;
  }

  void _detach() {
    terminal.onOutput = null;
    terminal.onResize = null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<TerminalCubit>();

    return BlocConsumer<TerminalCubit, TerminalState>(
      listener: (context, state) {
        if (state is TerminalConnected) {
          _attach(state.handle);
        } else if (state is TerminalDisconnected || state is TerminalFailure) {
          _detach();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 41,
            titleSpacing: 8,
            title: Text(
              "${widget.server.username}@${widget.server.host}",
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusDot(state),
              ),
            ],
          ),
          body: switch (state) {
            TerminalConnecting() => Center(
              child: Text("Connecting to ${widget.server.host}..."),
            ),
            TerminalFailure(:final message) => Center(
              child: Column(
                mainAxisSize: .min,
                spacing: 12,
                children: [
                  Icon(Icons.error),
                  Text("Connection failed: $message"),
                  FilledButton(
                    onPressed: cubit.reconnect,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
            TerminalDisconnected() => const Center(child: Text("Disconnected")),
            TerminalConnected() => TerminalView(
              terminal,
              theme: AppTerminalTheme.dark,
              padding: const EdgeInsets.all(12),
              autofocus: true,
              textStyle: TerminalStyle(
                fontSize: settings.terminalFontSize,
                fontFamily: settings.terminalFontFamily,
              ),
            ),
          },
        );
      },
    );
  }
}
