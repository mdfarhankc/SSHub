import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/theme/app_terminal_theme.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_picker_sheet.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
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

class _SearchMatch {
  final int line;
  final int startCol;
  final int endCol;
  const _SearchMatch(this.line, this.startCol, this.endCol);
}

class _TerminalPageState extends State<TerminalPage> {
  final terminal = Terminal(maxLines: 10000);
  final _terminalController = TerminalController();
  final _scrollController = ScrollController();
  SshSessionHandle? _handle;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;
  List<_SearchMatch> _matches = const [];
  int _matchIndex = 0;

  @override
  void dispose() {
    _terminalController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _attach(SshSessionHandle handle) {
    _handle = handle;
    handle.output.listen(terminal.write);
    terminal.onOutput = handle.write;
    terminal.onResize = handle.resize;
  }

  void _detach() {
    _handle = null;
    terminal.onOutput = null;
    terminal.onResize = null;
  }

  Future<void> _copySelection() async {
    final selection = _terminalController.selection;
    if (selection == null) return;
    final text = terminal.buffer.getText(selection);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _terminalController.clearSelection();
    if (mounted) showAppSnackBar(context, "Copied to clipboard");
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) terminal.paste(text);
  }

  void _selectAll() {
    _terminalController.setSelection(
      terminal.buffer.createAnchor(0, 0),
      terminal.buffer.createAnchor(
        terminal.viewWidth,
        terminal.buffer.height - 1,
      ),
      mode: SelectionMode.line,
    );
  }

  // Ctrl+L: ask the shell to redraw a clean screen.
  void _clear() => _handle?.write('\x0c');

  void _showSnippets(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SnippetPickerSheet(
        onSelected: (snippet) => terminal.textInput(snippet.value),
      ),
    );
  }

  // Ctrl+C copies when there's a selection, otherwise falls through as SIGINT.
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

    if (modifier &&
        !keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      _openSearch();
      return KeyEventResult.handled;
    }

    if (!Platform.isMacOS &&
        keyboard.isControlPressed &&
        !keyboard.isShiftPressed &&
        !keyboard.isMetaPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC &&
        _terminalController.selection != null) {
      _copySelection();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _showContextMenu(BuildContext context, Offset globalPos) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final hasSelection = _terminalController.selection != null;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: 'copy',
          child: _MenuRow(
            icon: Icons.copy_rounded,
            label: "Copy",
            hint: "Ctrl+Shift+C",
          ),
        ),
        PopupMenuItem(
          value: 'paste',
          child: _MenuRow(
            icon: Icons.content_paste_rounded,
            label: "Paste",
            hint: "Ctrl+V",
          ),
        ),
        PopupMenuItem(
          value: 'selectAll',
          child: _MenuRow(
            icon: Icons.select_all_rounded,
            label: "Select all",
            hint: "Ctrl+A",
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'find',
          child: _MenuRow(
            icon: Icons.search_rounded,
            label: "Find",
            hint: "Ctrl+F",
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          child: _MenuRow(
            icon: Icons.cleaning_services_outlined,
            label: "Clear screen",
            hint: "Ctrl+L",
          ),
        ),
      ],
    );
    if (choice == 'copy' && !hasSelection) return;
    switch (choice) {
      case 'copy':
        _copySelection();
      case 'paste':
        _paste();
      case 'selectAll':
        _selectAll();
      case 'find':
        _openSearch();
      case 'clear':
        _clear();
    }
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _searchFocus.requestFocus();
    if (_searchController.text.isNotEmpty) _runSearch(_searchController.text);
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _matches = const [];
      _matchIndex = 0;
    });
    _terminalController.clearSelection();
  }

  void _runSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _matches = const [];
        _matchIndex = 0;
      });
      _terminalController.clearSelection();
      return;
    }
    final needle = query.toLowerCase();
    final matches = <_SearchMatch>[];
    final lines = terminal.buffer.lines;
    for (var y = 0; y < terminal.buffer.height; y++) {
      final text = lines[y].getText().toLowerCase();
      var start = text.indexOf(needle);
      while (start != -1) {
        matches.add(_SearchMatch(y, start, start + query.length));
        start = text.indexOf(needle, start + query.length);
      }
    }
    setState(() {
      _matches = matches;
      _matchIndex = 0;
    });
    if (matches.isNotEmpty) {
      _gotoMatch(0);
    } else {
      _terminalController.clearSelection();
    }
  }

  void _gotoMatch(int index) {
    if (_matches.isEmpty) return;
    final match = _matches[index];
    _terminalController.setSelection(
      terminal.buffer.createAnchor(match.startCol, match.line),
      terminal.buffer.createAnchor(match.endCol, match.line),
      mode: SelectionMode.line,
    );
    _scrollToLine(match.line);
    setState(() => _matchIndex = index);
  }

  void _nextMatch() {
    if (_matches.isNotEmpty) _gotoMatch((_matchIndex + 1) % _matches.length);
  }

  void _prevMatch() {
    if (_matches.isNotEmpty) {
      _gotoMatch((_matchIndex - 1 + _matches.length) % _matches.length);
    }
  }

  // Scroll extent maps 1:1 to buffer lines, so cell height derives from it.
  void _scrollToLine(int line) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final scrollableRows = terminal.buffer.height - terminal.viewHeight;
    if (scrollableRows <= 0 || position.maxScrollExtent <= 0) return;
    final cellHeight = position.maxScrollExtent / scrollableRows;
    final target = ((line - terminal.viewHeight ~/ 2) * cellHeight).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
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
          context.read<ServerListBloc>().add(
            ServerUpdated(
              widget.server.copyWith(lastConnectedAt: DateTime.now()),
            ),
          );
        } else if (state is TerminalDisconnected ||
            state is TerminalFailure ||
            state is TerminalReconnecting) {
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
              if (state is TerminalConnected) ...[
                IconButton(
                  tooltip: "Find (Ctrl+F)",
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _openSearch,
                ),
                IconButton(
                  tooltip: "Snippets",
                  icon: const Icon(Icons.bolt_outlined),
                  onPressed: () => _showSnippets(context),
                ),
              ],
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: StatusDot(state),
              ),
            ],
          ),
          body: switch (state) {
            TerminalConnecting() => _StatusView(
              indicator: const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              title: "Connecting",
              message:
                  "Establishing a secure SSH channel to ${widget.server.host}",
            ),
            TerminalReconnecting(:final attempt, :final maxAttempts) =>
              _StatusView(
                indicator: const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
                title: "Reconnecting",
                message:
                    "Connection lost. Reconnecting to ${widget.server.host} "
                    "(attempt $attempt of $maxAttempts)...",
              ),
            TerminalFailure(:final message) => _StatusView(
              indicator: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
              title: "Connection Failed",
              titleColor: theme.colorScheme.error,
              message: message,
              primaryLabel: "Try Again",
              onPrimary: cubit.reconnect,
            ),
            TerminalDisconnected() => _StatusView(
              indicator: Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: "Disconnected",
              message: "The SSH session has ended.",
              primaryLabel: "Reconnect",
              onPrimary: cubit.reconnect,
            ),
            TerminalConnected() => Column(
              children: [
                if (_searchOpen) _buildSearchBar(context),
                Expanded(
                  child: TerminalView(
                    terminal,
                    controller: _terminalController,
                    scrollController: _scrollController,
                    theme: isDark
                        ? AppTerminalTheme.dark
                        : AppTerminalTheme.light,
                    padding: const EdgeInsets.all(12),
                    autofocus: true,
                    onSecondaryTapDown: (details, _) =>
                        _showContextMenu(context, details.globalPosition),
                    onKeyEvent: (node, event) =>
                        _handleTerminalKey(context, event),
                    textStyle: TerminalStyle(
                      fontSize: settings.terminalFontSize,
                      fontFamily: settings.terminalFontFamily,
                    ),
                  ),
                ),
                if (Platform.isAndroid || Platform.isIOS)
                  TerminalKeyBar(terminal: terminal),
              ],
            ),
          },
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasMatches = _matches.isNotEmpty;
    final count = hasMatches ? "${_matchIndex + 1}/${_matches.length}" : "0/0";

    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      _closeSearch,
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                      _prevMatch,
                },
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: true,
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "Find in terminal",
                  ),
                  onChanged: _runSearch,
                  onSubmitted: (_) => _nextMatch(),
                ),
              ),
            ),
            Text(
              count,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              tooltip: "Previous (Shift+Enter)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              onPressed: hasMatches ? _prevMatch : null,
            ),
            IconButton(
              tooltip: "Next (Enter)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              onPressed: hasMatches ? _nextMatch : null,
            ),
            IconButton(
              tooltip: "Close (Esc)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _closeSearch,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  const _MenuRow({required this.icon, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label),
        const SizedBox(width: 24),
        const Spacer(),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// Shared layout for the connecting/failed/disconnected states so they keep the
// same width, sizing, and spacing.
class _StatusView extends StatelessWidget {
  final Widget indicator;
  final String title;
  final Color? titleColor;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  const _StatusView({
    required this.indicator,
    required this.title,
    this.titleColor,
    this.message,
    this.primaryLabel,
    this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 64, child: Center(child: indicator)),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (onPrimary != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: onPrimary,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(primaryLabel!),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Servers"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
