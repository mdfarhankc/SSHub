import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/auth/reveal_guard.dart';
import 'package:sshub/core/platform/system_bell.dart';
import 'package:sshub/core/security/secure_platform.dart';
import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/theme/terminal_schemes.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_session.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_picker_sheet.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_key_bar.dart';
import 'package:sshub/features/ssh/presentation/widgets/terminal_search.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

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
  // How long the visual bell flash stays lit, and how long the selection must
  // settle before copy-on-select fires.
  static const _bellFlashDuration = Duration(milliseconds: 120);
  static const _copyDebounce = Duration(milliseconds: 150);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _terminalFocus = FocusNode();
  late final TerminalSearchController _search = TerminalSearchController(
    _terminal,
  );
  bool _searchOpen = false;
  // Scrollback is only worth showing after a session actually produced any.
  bool _everConnected = false;

  // Copy-on-select fires after the selection stops changing, not every drag
  // frame. The bell flash clears itself shortly after it lights up.
  Timer? _copyTimer;
  Timer? _bellTimer;
  bool _bellFlash = false;
  // Search and select-all set the selection in code; those must not auto-copy.
  bool _suppressAutoCopy = false;

  Terminal get _terminal => widget.session.terminal;
  TerminalController get _terminalController =>
      widget.session.terminalController;

  @override
  void initState() {
    super.initState();
    _terminal.onBell = _onBell;
    _terminalController.addListener(_onSelectionChanged);
    // The search model finds matches; this view applies the selection and
    // scrolls to whichever one is current.
    _search.addListener(_onSearchMatchChanged);
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
    _terminal.onBell = null;
    _terminalController.removeListener(_onSelectionChanged);
    _search.removeListener(_onSearchMatchChanged);
    _search.dispose();
    _copyTimer?.cancel();
    _bellTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _terminalFocus.dispose();
    super.dispose();
  }

  void _onBell() {
    if (!mounted) return;
    final settings = context.read<SettingsCubit>().state.settings;
    if (settings.bellSound) SystemBell.ring();
    if (!settings.bellVisual) return;
    setState(() => _bellFlash = true);
    _bellTimer?.cancel();
    _bellTimer = Timer(_bellFlashDuration, () {
      if (mounted) setState(() => _bellFlash = false);
    });
  }

  // Copies once the selection settles, so a drag does not spam the clipboard.
  void _onSelectionChanged() {
    if (!mounted || _suppressAutoCopy) return;
    if (!context.read<SettingsCubit>().state.settings.copyOnSelect) return;
    if (_terminalController.selection == null) return;
    _copyTimer?.cancel();
    _copyTimer = Timer(_copyDebounce, () {
      final selection = _terminalController.selection;
      if (selection == null) return;
      final text = _terminal.buffer.getText(selection);
      if (text.isNotEmpty) SecurePlatform.copySensitive(text);
    });
  }

  // Runs [body] with auto-copy muted, restoring the flag even if it throws so
  // a failed programmatic selection cannot leave copy-on-select stuck off.
  void _withoutAutoCopy(void Function() body) {
    _suppressAutoCopy = true;
    try {
      body();
    } finally {
      _suppressAutoCopy = false;
    }
  }

  // Selects the current search match and scrolls it into view, or clears the
  // selection when the query stops matching.
  void _onSearchMatchChanged() {
    final match = _search.current;
    if (match == null) {
      _terminalController.clearSelection();
      return;
    }
    _withoutAutoCopy(() {
      _terminalController.setSelection(
        _terminal.buffer.createAnchor(match.startCol, match.line),
        _terminal.buffer.createAnchor(match.endCol, match.line),
        mode: SelectionMode.line,
      );
    });
    _scrollToLine(match.line);
  }

  TerminalCursorType _cursorType(String style) => switch (style) {
    "Bar" => TerminalCursorType.verticalBar,
    "Underline" => TerminalCursorType.underline,
    _ => TerminalCursorType.block,
  };

  Future<void> _copySelection() async {
    final selection = _terminalController.selection;
    if (selection == null) return;
    final text = _terminal.buffer.getText(selection);
    if (text.isEmpty) return;
    await SecurePlatform.copySensitive(text);
    _terminalController.clearSelection();
    if (mounted) showAppSnackBar(context, "Copied to clipboard");
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) _terminal.paste(text);
  }

  void _selectAll() {
    _withoutAutoCopy(() {
      _terminalController.setSelection(
        _terminal.buffer.createAnchor(0, 0),
        _terminal.buffer.createAnchor(
          _terminal.viewWidth,
          _terminal.buffer.height - 1,
        ),
        mode: SelectionMode.line,
      );
    });
  }

  // Ctrl+L: ask the shell to redraw a clean screen.
  void _clear() {
    final state = widget.session.state;
    if (state is TerminalConnected) state.handle.write('\x0c');
  }

  void showSnippets() {
    showBlurredBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SnippetPickerSheet(onSelected: _pasteSnippet),
    );
  }

  // Typing a snippet puts its value on screen, so it goes through the same
  // gate as revealing one.
  Future<void> _pasteSnippet(Snippet snippet) async {
    final locked = context
        .read<SettingsCubit>()
        .state
        .settings
        .lockSnippetReveal;
    final allowed = await context.confirmReveal(
      locked: locked,
      reason: "Paste ${snippet.label}",
    );
    if (allowed) _terminal.textInput(snippet.value);
  }

  void _closeThisTab() {
    final sessions = context.read<WorkspaceSessionsCubit>();
    final index = sessions.state.sessions.indexWhere(
      (s) => s is TerminalWorkspaceSession && s.cubit == widget.session,
    );
    if (index != -1) sessions.closeSession(index);
  }

  // Once a session has produced output, the scrollback is the most useful
  // thing on screen, so it stays visible under a banner instead of being
  // replaced by a status page.
  Widget _endedView(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget fallback,
    bool isError = false,
    bool busy = false,
  }) {
    if (!_everConnected) return fallback;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Material(
          color: isError ? scheme.errorContainer : scheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    isError ? LucideIcons.circleAlert : LucideIcons.cloudOff,
                    size: 18,
                    color: isError ? scheme.onErrorContainer : scheme.onSurface,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isError
                          ? scheme.onErrorContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final settings = context.watch<SettingsCubit>().state.settings;
              return TerminalView(
                _terminal,
                controller: _terminalController,
                scrollController: _scrollController,
                theme: TerminalSchemes.resolve(
                  settings.terminalColorScheme,
                  dark: theme.brightness == Brightness.dark,
                ),
                padding: const EdgeInsets.all(12),
                readOnly: true,
                textStyle: TerminalStyle(
                  fontSize: settings.terminalFontSize,
                  fontFamily: settings.terminalFontFamily,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
        case LogicalKeyboardKey.keyC:
          _copySelection();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyV:
          _paste();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyA:
          _selectAll();
          return KeyEventResult.handled;
      }
    }

    if (modifier && event.logicalKey == LogicalKeyboardKey.tab) {
      final sessions = context.read<WorkspaceSessionsCubit>();
      keyboard.isShiftPressed ? sessions.previous() : sessions.next();
      return KeyEventResult.handled;
    }

    if (keyboard.isAltPressed) {
      final index = sessionDigitKeys.indexOf(event.logicalKey);
      if (index != -1) {
        context.read<WorkspaceSessionsCubit>().setActive(index);
        return KeyEventResult.handled;
      }
    }

    if (modifier &&
        !keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      openSearch();
      return KeyEventResult.handled;
    }

    // Ctrl+C is left to the shell. Copying it instead would swallow the
    // interrupt whenever a stale selection is lying around.
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
            hint: "Ctrl+Shift+V",
          ),
        ),
        PopupMenuItem(
          value: 'selectAll',
          child: _MenuRow(
            icon: LucideIcons.textSelect,
            label: "Select all",
            hint: "Ctrl+Shift+A",
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
    if (_searchController.text.isNotEmpty) _search.run(_searchController.text);
  }

  void _closeSearch() {
    setState(() => _searchOpen = false);
    _search.clear();
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
    if (context.read<SettingsCubit>().state.settings.reduceMotion) {
      _scrollController.jumpTo(target);
      return;
    }
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
            _everConnected = true;
            _focusTerminal();
            context.read<ServerListBloc>().add(ServerConnected(server.id));
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
              _endedView(
                context,
                message:
                    "Connection lost. Reconnecting to ${server.host} "
                    "(attempt $attempt of $maxAttempts)...",
                actionLabel: "Stop",
                onAction: widget.session.stopReconnecting,
                busy: true,
                fallback: _StatusView(
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
              ),
            TerminalFailure(:final message) => _endedView(
              context,
              message: message,
              actionLabel: "Try Again",
              onAction: widget.session.reconnect,
              isError: true,
              fallback: _StatusView(
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
            ),
            TerminalDisconnected() => _endedView(
              context,
              message: "The SSH session has ended.",
              actionLabel: "Reconnect",
              onAction: widget.session.reconnect,
              fallback: _StatusView(
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
            ),
            TerminalConnected() => Column(
              children: [
                if (_searchOpen)
                  TerminalSearchBar(
                    controller: _search,
                    textController: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _search.run,
                    onNext: _search.next,
                    onPrevious: _search.previous,
                    onClose: _closeSearch,
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      TerminalView(
                        _terminal,
                        controller: _terminalController,
                        scrollController: _scrollController,
                        focusNode: _terminalFocus,
                        theme: TerminalSchemes.resolve(
                          settings.terminalColorScheme,
                          dark: isDark,
                        ),
                        padding: const EdgeInsets.all(12),
                        autofocus: widget.isActive,
                        cursorType: _cursorType(settings.cursorStyle),
                        onSecondaryTapDown: (details, _) =>
                            settings.pasteOnRightClick
                            ? _paste()
                            : _showContextMenu(context, details.globalPosition),
                        onKeyEvent: (node, event) =>
                            _handleTerminalKey(context, event),
                        textStyle: TerminalStyle(
                          fontSize: settings.terminalFontSize,
                          fontFamily: settings.terminalFontFamily,
                        ),
                      ),
                      if (_bellFlash)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                        ),
                    ],
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
