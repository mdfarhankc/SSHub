import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const route = "/help";

  @override
  Widget build(BuildContext context) {
    final mod = shortcutModifierLabel;
    final overrides = context.select<SettingsCubit, Map<String, String>>(
      (c) => c.state.settings.shortcutOverrides,
    );

    final shortcuts = <(String, String)>[
      for (final def in kShortcutDefs)
        (bindingFor(def.action, overrides).display, def.label),
      ("$mod+Tab", "Switch to the next tab"),
      ("Alt+1-9", "Jump to a tab by number"),
      ("F1", "Open this help"),
    ];

    final guides = <(IconData, String, String)>[
      (
        LucideIcons.server,
        "Servers",
        "Add SSH connections with the + button and tag them with a colour. "
            "Tap a card to open a terminal. Long-press or right-click a card "
            "for Open, Browse Files, Edit, Forget Host Key or Remove.",
      ),
      (
        LucideIcons.appWindow,
        "Tabs and workspace",
        "Terminals and file browsers share one tab strip and stay connected "
            "while you browse your servers. Add tabs with the + in the tab "
            "bar, and right-click a tab to duplicate it or close others.",
      ),
      (
        LucideIcons.zap,
        "Snippets",
        "Save reusable text. A Secret stays hidden and reveal-gated; a Command "
            "is shown in full. In a terminal, ${bindingFor(ShortcutAction.snippets, overrides).display} "
            "opens the picker to insert, run or copy one. Commands can carry "
            "{{host}}, {{user}} or {{port}} for the current session, or "
            "{{prompt:Label}} to ask for a value when used.",
      ),
      (
        LucideIcons.textCursorInput,
        "Selecting and copying",
        "Drag to select, and keep dragging past the top or bottom edge to "
            "scroll through the scrollback. Hold Shift to extend a selection. "
            "$mod+C copies when text is selected, otherwise it interrupts the "
            "running program. A large or multi-line paste asks first.",
      ),
      (
        LucideIcons.keyboard,
        "Custom shortcuts",
        "Settings > Shortcuts lets you rebind most actions. Tap a shortcut's "
            "button and press the new combination.",
      ),
      (
        LucideIcons.lock,
        "App lock",
        "Settings > Security can require your device biometrics or lock to "
            "open SSHub and before revealing saved passwords or snippet values.",
      ),
      (
        LucideIcons.databaseBackup,
        "Backup",
        "Settings > Data exports your servers, snippets and settings to an "
            "encrypted file you can import on another device.",
      ),
      (
        LucideIcons.fingerprint,
        "Known hosts",
        "SSHub remembers each server's SSH host key. If a server is rebuilt "
            "and its key changes, forget the old key from the card menu or "
            "Settings > Known hosts.",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Help")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              const _SectionLabel("Keyboard shortcuts"),
              const SizedBox(height: 8),
              for (final (keys, desc) in shortcuts)
                _ShortcutRow(keys: keys, description: desc),
              const SizedBox(height: 28),
              const _SectionLabel("Guides"),
              const SizedBox(height: 8),
              for (final (icon, title, body) in guides)
                _GuideCard(icon: icon, title: title, body: body),
            ],
          ),
        ),
      ),
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

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String description;
  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final key in keys.split('+')) _Kbd(key)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(description, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Kbd extends StatelessWidget {
  final String label;
  const _Kbd(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.mono,
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
