import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_terminal_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_key_bar.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

class _SearchMatch {
  final int line;
  final int startCol;
  final int endCol;
  const _SearchMatch(this.line, this.startCol, this.endCol);
}

// One tab's body. The session owns the terminal and its scrollback, so this
// widget only renders it and handles view-level concerns like search.
class TerminalSessionView extends StatefulWidget {
  final TerminalCubit session;
  final bool isActive;
  const TerminalSessionView({
    super.key,
    required this.session,
    required this.isActive,
  });

  @override
  State<TerminalSessionView> createState() => TerminalSessionViewState();
}

class TerminalSessionViewState extends State<TerminalSessionView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _terminalFocus = FocusNode();
  bool _searchOpen = false;
  List<_SearchMatch> _matches = const [];
  int _matchIndex = 0;

  Terminal get _terminal => widget.session.terminal;
  TerminalController get _terminalController =>
      widget.session.terminalController;

  @override
  void initState() {
    super.initState();
    // A tab opened from the tab bar is born active, so it never sees a change
    // of isActive to focus on.
    if (widget.isActive) _focusTerminal();
  }

  // Every tab stays mounted, so focus has to follow the visible one or typing
  // would land in whichever terminal was focused last.
  @override
  void didUpdateWidget(TerminalSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      _focusTerminal();
    } else {
      _terminalFocus.unfocus();
    }
  }

  // The terminal only exists once the session connects, so the request has to
  // outlive the frame that asked for it, and the tab may have moved on by then.
  void _focusTerminal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive || _searchOpen) return;
      _terminalFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _terminalFocus.dispose();
    super.dispose();
  }

  Future<void> _copySelection() async {
    final selection = _terminalController.selection;
    if (selection == null) return;
    final text = _terminal.buffer.getText(selection);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _terminalController.clearSelection();
    if (mounted) showAppSnackBar(context, "Copied to clipboard");
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) _terminal.paste(text);
  }

  void _selectAll() {
    _terminalController.setSelection(
      _terminal.buffer.createAnchor(0, 0),
      _terminal.buffer.createAnchor(
        _terminal.viewWidth,
        _terminal.buffer.height - 1,
      ),
      mode: SelectionMode.line,
    );
  }

  // Ctrl+L: ask the shell to redraw a clean screen.
  void _clear() {
    final state = widget.session.state;
    if (state is TerminalConnected) state.handle.write('\x0c');
  }

  void showSnippets() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SnippetPickerSheet(
        onSelected: (snippet) => _terminal.textInput(snippet.value),
      ),
    );
  }

  void _closeThisTab() {
    final sessions = context.read<TerminalSessionsCubit>();
    final index = sessions.state.sessions.indexOf(widget.session);
    if (index != -1) sessions.closeSession(index);
  }

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

  // The terminal has focus and forwards most keys to the shell, so tab and
  // session shortcuts are intercepted here rather than via ancestor Shortcuts.
  // Ctrl+W and Ctrl+T are deliberately left alone: the shell uses them.
  KeyEventResult _handleTerminalKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final modifier = keyboard.isControlPressed || keyboard.isMetaPressed;

    if (modifier && keyboard.isShiftPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyS:
          showSnippets();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyT:
          ServerPickerSheet.openSession(context);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyW:
          _closeThisTab();
          return KeyEventResult.handled;
      }
    }

    if (modifier && event.logicalKey == LogicalKeyboardKey.tab) {
      final sessions = context.read<TerminalSessionsCubit>();
      keyboard.isShiftPressed ? sessions.previous() : sessions.next();
      return KeyEventResult.handled;
    }

    if (keyboard.isAltPressed) {
      final index = _digits.indexOf(event.logicalKey);
      if (index != -1) {
        context.read<TerminalSessionsCubit>().setActive(index);
        return KeyEventResult.handled;
      }
    }

    if (modifier &&
        !keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      openSearch();
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
            icon: LucideIcons.copy,
            label: "Copy",
            hint: "Ctrl+Shift+C",
          ),
        ),
        PopupMenuItem(
          value: 'paste',
          child: _MenuRow(
            icon: LucideIcons.clipboardPaste,
            label: "Paste",
            hint: "Ctrl+V",
          ),
        ),
        PopupMenuItem(
          value: 'selectAll',
          child: _MenuRow(
            icon: LucideIcons.textSelect,
            label: "Select all",
            hint: "Ctrl+A",
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'find',
          child: _MenuRow(
            icon: LucideIcons.search,
            label: "Find",
            hint: "Ctrl+F",
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          child: _MenuRow(
            icon: LucideIcons.brushCleaning,
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
        openSearch();
      case 'clear':
        _clear();
    }
  }

  void openSearch() {
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
    final lines = _terminal.buffer.lines;
    for (var y = 0; y < _terminal.buffer.height; y++) {
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
      _terminal.buffer.createAnchor(match.startCol, match.line),
      _terminal.buffer.createAnchor(match.endCol, match.line),
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
    final scrollableRows = _terminal.buffer.height - _terminal.viewHeight;
    if (scrollableRows <= 0 || position.maxScrollExtent <= 0) return;
    final cellHeight = position.maxScrollExtent / scrollableRows;
    final target = ((line - _terminal.viewHeight ~/ 2) * cellHeight).clamp(
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
    final server = widget.session.server;
    final isDark = theme.brightness == Brightness.dark;

    return ExcludeFocus(
      // A background tab is still mounted, so nothing in it may hold focus or
      // it would receive the keystrokes meant for the visible session.
      excluding: !widget.isActive,
      child: BlocConsumer<TerminalCubit, TerminalState>(
        bloc: widget.session,
        listener: (context, state) {
          if (state is TerminalConnected) {
            _focusTerminal();
            context.read<ServerListBloc>().add(
              ServerUpdated(server.copyWith(lastConnectedAt: DateTime.now())),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            TerminalConnecting() => _StatusView(
              indicator: const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              title: "Connecting",
              message: "Establishing a secure SSH channel to ${server.host}",
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
                    "Connection lost. Reconnecting to ${server.host} "
                    "(attempt $attempt of $maxAttempts)...",
              ),
            TerminalFailure(:final message) => _StatusView(
              indicator: Icon(
                LucideIcons.circleAlert,
                size: 56,
                color: theme.colorScheme.error,
              ),
              title: "Connection Failed",
              titleColor: theme.colorScheme.error,
              message: message,
              primaryLabel: "Try Again",
              onPrimary: widget.session.reconnect,
            ),
            TerminalDisconnected() => _StatusView(
              indicator: Icon(
                LucideIcons.cloudOff,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: "Disconnected",
              message: "The SSH session has ended.",
              primaryLabel: "Reconnect",
              onPrimary: widget.session.reconnect,
            ),
            TerminalConnected() => Column(
              children: [
                if (_searchOpen) _buildSearchBar(context),
                Expanded(
                  child: TerminalView(
                    _terminal,
                    controller: _terminalController,
                    scrollController: _scrollController,
                    focusNode: _terminalFocus,
                    theme: isDark
                        ? AppTerminalTheme.dark
                        : AppTerminalTheme.light,
                    padding: const EdgeInsets.all(12),
                    autofocus: widget.isActive,
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
                  TerminalKeyBar(terminal: _terminal),
              ],
            ),
          };
        },
      ),
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
            Icon(LucideIcons.search, size: 18, color: scheme.onSurfaceVariant),
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
              icon: const Icon(LucideIcons.chevronUp, size: 20),
              onPressed: hasMatches ? _prevMatch : null,
            ),
            IconButton(
              tooltip: "Next (Enter)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.chevronDown, size: 20),
              onPressed: hasMatches ? _nextMatch : null,
            ),
            IconButton(
              tooltip: "Close (Esc)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.x, size: 20),
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
                    icon: const Icon(LucideIcons.refreshCw),
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
