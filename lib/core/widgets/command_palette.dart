import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';

// One runnable entry in the command palette.
class PaletteCommand {
  final String label;
  final IconData icon;
  final VoidCallback onRun;
  // A secondary line, such as a category or a host.
  final String? hint;
  // A trailing label, such as the command's shortcut.
  final String? trailing;

  const PaletteCommand({
    required this.label,
    required this.icon,
    required this.onRun,
    this.hint,
    this.trailing,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();
    return label.toLowerCase().contains(needle) ||
        (hint?.toLowerCase().contains(needle) ?? false);
  }
}

// A keyboard-first command palette: type to filter, arrows to move, Enter to
// run, Esc to close.
Future<void> showCommandPalette(
  BuildContext context, {
  required List<PaletteCommand> commands,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _CommandPalette(commands: commands),
  );
}

class _CommandPalette extends StatefulWidget {
  final List<PaletteCommand> commands;
  const _CommandPalette({required this.commands});

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String _query = "";
  int _selected = 0;

  static const _itemHeight = 54.0;

  List<PaletteCommand> get _filtered => [
    for (final c in widget.commands)
      if (c.matches(_query)) c,
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _selected = 0;
    });
    _scrollToSelected();
  }

  void _move(int delta) {
    final count = _filtered.length;
    if (count == 0) return;
    setState(() => _selected = (_selected + delta).clamp(0, count - 1));
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    // The list has 6px of vertical padding, so a row's top sits that far down.
    const listPad = 6.0;
    final itemTop = listPad + _selected * _itemHeight;
    final viewTop = _scroll.offset;
    final viewBottom = viewTop + _scroll.position.viewportDimension;
    if (itemTop < viewTop) {
      _scroll.jumpTo(itemTop - listPad);
    } else if (itemTop + _itemHeight > viewBottom) {
      _scroll.jumpTo(itemTop + _itemHeight - _scroll.position.viewportDimension);
    }
  }

  void _runSelected() {
    final items = _filtered;
    if (_selected >= 0 && _selected < items.length) _run(items[_selected]);
  }

  void _run(PaletteCommand command) {
    Navigator.of(context).pop();
    command.onRun();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _filtered;
    if (_selected >= items.length) {
      _selected = items.isEmpty ? 0 : items.length - 1;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _runSelected,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _runSelected,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Align(
        alignment: const Alignment(0, -0.55),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onQueryChanged,
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        prefixIcon: Icon(LucideIcons.search, size: 20),
                        hintText: "Type a command or server...",
                      ),
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              "No matches",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: items.length,
                            itemExtent: _itemHeight,
                            itemBuilder: (context, i) => _PaletteRow(
                              command: items[i],
                              selected: i == _selected,
                              onTap: () => _run(items[i]),
                              onHover: () => setState(() => _selected = i),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final PaletteCommand command;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;
  const _PaletteRow({
    required this.command,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                command.icon,
                size: 18,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (command.hint != null)
                      Text(
                        command.hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (command.trailing != null) ...[
                const SizedBox(width: 10),
                Text(
                  command.trailing!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: AppTheme.mono,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
