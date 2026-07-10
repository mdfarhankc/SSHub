import 'package:flutter/material.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

class TerminalKeyBar extends StatelessWidget {
  final Terminal terminal;
  const TerminalKeyBar({super.key, required this.terminal});

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
            _KeyButton(label: "ESC", onTap: () => _send(TerminalKey.escape)),
            _KeyButton(label: "TAB", onTap: () => _send(TerminalKey.tab)),
            _KeyButton(
              label: "CTRL+C",
              onTap: () => _send(TerminalKey.keyC, ctrl: true),
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
