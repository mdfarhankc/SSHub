import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/core/theme/app_theme.dart';

final _modifierKeys = {
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

// Captures a key combination for [def]. Returns the new binding, or null if
// cancelled.
class ShortcutRecorderDialog extends StatefulWidget {
  final ShortcutDef def;
  const ShortcutRecorderDialog({super.key, required this.def});

  static Future<KeyBinding?> show(BuildContext context, ShortcutDef def) =>
      showDialog<KeyBinding>(
        context: context,
        builder: (_) => ShortcutRecorderDialog(def: def),
      );

  @override
  State<ShortcutRecorderDialog> createState() => _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<ShortcutRecorderDialog> {
  KeyBinding? _pending;
  bool _needsPrimary = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final key = event.logicalKey;
    if (_modifierKeys.contains(key)) return KeyEventResult.handled;

    final keyboard = HardwareKeyboard.instance;
    final primary = keyboard.isControlPressed || keyboard.isMetaPressed;

    if (key == LogicalKeyboardKey.escape && !primary) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    // Every app shortcut carries the primary modifier, so a lone key is not a
    // valid capture.
    setState(() {
      _needsPrimary = !primary;
      if (primary) {
        _pending = KeyBinding(
          key,
          primary: true,
          shift: keyboard.isShiftPressed,
          alt: keyboard.isAltPressed,
        );
      }
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mod = shortcutModifierLabel;
    final pending = _pending;

    return AlertDialog(
      title: Text(widget.def.label),
      content: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Center(
                child: pending == null
                    ? Text(
                        "Press a shortcut...",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : _Combo(pending.display),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _needsPrimary
                  ? "Include $mod, for example $mod Shift and a key."
                  : "Press Esc to cancel.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: _needsPrimary ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: pending == null
              ? null
              : () => Navigator.pop(context, pending),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _Combo extends StatelessWidget {
  final String combo;
  const _Combo(this.combo);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: 6,
      children: [
        for (final key in combo.split("+"))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              key,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.mono,
              ),
            ),
          ),
      ],
    );
  }
}
