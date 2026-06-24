import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

class TerminalKeyBar extends StatelessWidget {
  final Terminal terminal;
  final VoidCallback? onSnippets;
  const TerminalKeyBar({super.key, required this.terminal, this.onSnippets});

  void _send(TerminalKey key, {bool ctrl = false}) =>
      terminal.keyInput(key, ctrl: ctrl);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeFocus(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            if (onSnippets != null) ...[
              _KeyButton(icon: Icons.bolt, onTap: onSnippets!),
              const VerticalDivider(width: 16, indent: 8, endIndent: 8),
            ],
            _KeyButton(label: "ESC", onTap: () => _send(TerminalKey.escape)),
            _KeyButton(label: "TAB", onTap: () => _send(TerminalKey.tab)),
            _KeyButton(
              label: "CTRL+C",
              onTap: () => _send(TerminalKey.keyC, ctrl: true),
            ),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
            _KeyButton(
              icon: Icons.keyboard_arrow_up,
              onTap: () => _send(TerminalKey.arrowUp),
            ),
            _KeyButton(
              icon: Icons.keyboard_arrow_down,
              onTap: () => _send(TerminalKey.arrowDown),
            ),
            _KeyButton(
              icon: Icons.keyboard_arrow_left,
              onTap: () => _send(TerminalKey.arrowLeft),
            ),
            _KeyButton(
              icon: Icons.keyboard_arrow_right,
              onTap: () => _send(TerminalKey.arrowRight),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _KeyButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: icon != null
                ? Icon(icon, size: 20, color: scheme.primary)
                : Text(
                    label!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
