import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/theme/app_terminal_theme.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_picker_sheet.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/status_dot.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_key_bar.dart';
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

  void _showSnippets(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SnippetPickerSheet(
        onSelected: (snippet) => terminal.textInput(snippet.value),
      ),
    );
  }

  // Intercept the snippets shortcut before the terminal consumes the keys, so
  // Ctrl/Cmd+Shift+S never reaches the shell as flow control.
  KeyEventResult _handleTerminalKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final modifier = keyboard.isControlPressed || keyboard.isMetaPressed;
    if (modifier &&
        keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyS) {
      _showSnippets(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<TerminalCubit>();
    final isDark = theme.brightness == Brightness.dark;

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.server.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.server.username}@${widget.server.host}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: AppTheme.mono,
                  ),
                ),
              ],
            ),
            actions: [
              if (state is TerminalConnected)
                IconButton(
                  tooltip: "Snippets",
                  icon: const Icon(Icons.bolt_outlined),
                  onPressed: () => _showSnippets(context),
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: StatusDot(state),
              ),
            ],
          ),
          body: switch (state) {
            TerminalConnecting() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    "Connecting to ${widget.server.host}...",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Establishing secure SSH channel",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TerminalFailure(:final message) => Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.errorContainer),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Connection Failed",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: cubit.reconnect,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Try Again"),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back to Servers"),
                    ),
                  ],
                ),
              ),
            ),
            TerminalDisconnected() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text("Disconnected", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: cubit.reconnect,
                    child: const Text("Reconnect"),
                  ),
                ],
              ),
            ),
            TerminalConnected() => Column(
              children: [
                Expanded(
                  child: TerminalView(
                    terminal,
                    theme: isDark
                        ? AppTerminalTheme.dark
                        : AppTerminalTheme.light,
                    padding: const EdgeInsets.all(12),
                    autofocus: true,
                    onKeyEvent: (node, event) =>
                        _handleTerminalKey(context, event),
                    textStyle: TerminalStyle(
                      fontSize: settings.terminalFontSize,
                      fontFamily: settings.terminalFontFamily,
                    ),
                  ),
                ),
                if (Platform.isAndroid || Platform.isIOS)
                  TerminalKeyBar(
                    terminal: terminal,
                    onSnippets: () => _showSnippets(context),
                  ),
              ],
            ),
          },
        );
      },
    );
  }
}
