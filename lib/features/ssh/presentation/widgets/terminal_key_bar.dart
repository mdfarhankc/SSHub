import 'package:flutter/material.dart';
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
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            children: [
              _KeyButton(label: "esc", onTap: () => _send(TerminalKey.escape)),
              _KeyButton(label: "tab", onTap: () => _send(TerminalKey.tab)),
              _KeyButton(
                label: "ctrl+c",
                onTap: () => _send(TerminalKey.keyC, ctrl: true),
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: icon != null
              ? Icon(icon, size: 18)
              : Text(label!, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
