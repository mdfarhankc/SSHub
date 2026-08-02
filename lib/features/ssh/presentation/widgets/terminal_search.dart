import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:xterm/xterm.dart';

import 'package:sshub/core/theme/app_theme.dart';

class TerminalSearchMatch {
  final int line;
  final int startCol;
  final int endCol;
  const TerminalSearchMatch(this.line, this.startCol, this.endCol);
}

// The search model for one terminal: finds matches and tracks the current one.
// Selection and scrolling stay with the view, so this holds no widget state.
class TerminalSearchController extends ChangeNotifier {
  TerminalSearchController(this._terminal);
  final Terminal _terminal;

  // Scanning the whole scrollback on every keystroke is wasteful, so the query
  // settles briefly before the scan runs.
  static const _debounce = Duration(milliseconds: 150);
  Timer? _debounceTimer;
  String _query = '';

  List<TerminalSearchMatch> _matches = const [];
  int _index = 0;

  List<TerminalSearchMatch> get matches => _matches;
  int get index => _index;
  bool get hasMatches => _matches.isNotEmpty;
  TerminalSearchMatch? get current =>
      _matches.isEmpty ? null : _matches[_index];

  void run(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      clear();
      return;
    }
    _query = query;
    _debounceTimer = Timer(_debounce, () => _scan(query));
  }

  void _scan(String query) {
    final needle = query.toLowerCase();
    final found = <TerminalSearchMatch>[];
    final lines = _terminal.buffer.lines;
    for (var y = 0; y < _terminal.buffer.height; y++) {
      final text = lines[y].getText().toLowerCase();
      var start = text.indexOf(needle);
      while (start != -1) {
        found.add(TerminalSearchMatch(y, start, start + query.length));
        start = text.indexOf(needle, start + query.length);
      }
    }
    _matches = found;
    _index = 0;
    notifyListeners();
  }

  // Runs a pending scan now so Enter acts on the latest query, not a stale one.
  void _flush() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _scan(_query);
    }
  }

  void next() {
    _flush();
    if (_matches.isEmpty) return;
    _index = (_index + 1) % _matches.length;
    notifyListeners();
  }

  void previous() {
    _flush();
    if (_matches.isEmpty) return;
    _index = (_index - 1 + _matches.length) % _matches.length;
    notifyListeners();
  }

  void clear() {
    _debounceTimer?.cancel();
    _matches = const [];
    _index = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// The find-in-terminal bar. It only reports intent; the view drives selection
// and scrolling through the controller's listener.
class TerminalSearchBar extends StatelessWidget {
  final TerminalSearchController controller;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  const TerminalSearchBar({
    super.key,
    required this.controller,
    required this.textController,
    required this.focusNode,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): onClose,
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                      onPrevious,
                },
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  autofocus: true,
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: "Find in terminal",
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onNext(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final hasMatches = controller.hasMatches;
                final hasQuery = textController.text.isNotEmpty;
                final noResults = hasQuery && !hasMatches;
                final pillColor = noResults
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHighest;
                final textColor = noResults
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant;
                final label = hasMatches
                    ? "${controller.index + 1} of ${controller.matches.length}"
                    : "No results";
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // No pill until there is something to count.
                    if (hasQuery) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _NavButton(
                      icon: LucideIcons.chevronUp,
                      tooltip: "Previous (Shift+Enter)",
                      onPressed: hasMatches ? onPrevious : null,
                    ),
                    _NavButton(
                      icon: LucideIcons.chevronDown,
                      tooltip: "Next (Enter)",
                      onPressed: hasMatches ? onNext : null,
                    ),
                  ],
                );
              },
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: scheme.outlineVariant,
            ),
            _NavButton(
              icon: LucideIcons.x,
              tooltip: "Close (Esc)",
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

// A compact icon button sized for the search bar's controls.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      splashRadius: 20,
      icon: Icon(
        icon,
        size: 18,
        color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
      onPressed: onPressed,
    );
  }
}
