import 'package:flutter/material.dart';
import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/theme/app_theme.dart';

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog(context: context, builder: (_) => const ShortcutsHelpDialog());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mod = shortcutModifierLabel;

    final shortcuts = <(String, String)>[
      ("$mod N", "Add a new server"),
      ("$mod F", "Search your servers"),
      ("$mod E", "Open snippets"),
      ("$mod ,", "Open settings"),
      ("$mod R", "Refresh server status"),
      ("$mod Shift D", "Toggle light and dark theme"),
      ("$mod Shift S", "Paste a snippet while in a terminal"),
      ("$mod Shift T", "Open another session in a new tab"),
      ("$mod Shift W", "Close the current tab"),
      ("$mod Tab", "Switch to the next tab"),
      ("Alt 1-9", "Jump to a tab by number"),
      ("F1", "Show this help"),
    ];

    final tips = <(IconData, String, String)>[
      (
        Icons.dns_rounded,
        "Servers",
        "Add SSH connections, tag them with a colour, then tap a card to open a live terminal.",
      ),
      (
        Icons.tab_rounded,
        "Tabs",
        "Keep several sessions open at once. Use + in the terminal to add one, and they stay connected while you browse your servers.",
      ),
      (
        Icons.bolt_rounded,
        "Snippets",
        "Save reusable tokens or commands once, then paste them into any terminal with a tap or $mod Shift S.",
      ),
      (
        Icons.lock_rounded,
        "App lock",
        "Protect SSHub with biometrics or your device lock, and require auth before revealing saved passwords or snippet values.",
      ),
      (
        Icons.backup_rounded,
        "Backup",
        "Export your servers, snippets and settings to an encrypted file, then import them on another device.",
      ),
    ];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          const Text("Help"),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 520 ? double.maxFinite : 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SectionLabel("Keyboard shortcuts"),
              const SizedBox(height: 8),
              for (final (keys, desc) in shortcuts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _Keys(keys),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(desc, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionLabel("Getting around"),
              const SizedBox(height: 8),
              for (final (icon, title, body) in tips)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Got it"),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  final String combo;
  const _Keys(this.combo);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 124,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final key in combo.split(' '))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                key,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.mono,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
