import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:xterm/xterm.dart';

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

  List<TerminalSearchMatch> _matches = const [];
  int _index = 0;

  List<TerminalSearchMatch> get matches => _matches;
  int get index => _index;
  bool get hasMatches => _matches.isNotEmpty;
  TerminalSearchMatch? get current =>
      _matches.isEmpty ? null : _matches[_index];

  void run(String query) {
    if (query.isEmpty) {
      clear();
      return;
    }
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

  void next() {
    if (_matches.isEmpty) return;
    _index = (_index + 1) % _matches.length;
    notifyListeners();
  }

  void previous() {
    if (_matches.isEmpty) return;
    _index = (_index - 1 + _matches.length) % _matches.length;
    notifyListeners();
  }

  void clear() {
    _matches = const [];
    _index = 0;
    notifyListeners();
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
                    border: InputBorder.none,
                    hintText: "Find in terminal",
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onNext(),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final hasMatches = controller.hasMatches;
                final count = hasMatches
                    ? "${controller.index + 1}/${controller.matches.length}"
                    : "0/0";
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      onPressed: hasMatches ? onPrevious : null,
                    ),
                    IconButton(
                      tooltip: "Next (Enter)",
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(LucideIcons.chevronDown, size: 20),
                      onPressed: hasMatches ? onNext : null,
                    ),
                  ],
                );
              },
            ),
            IconButton(
              tooltip: "Close (Esc)",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.x, size: 20),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
