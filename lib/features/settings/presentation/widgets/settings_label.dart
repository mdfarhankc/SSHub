import 'package:flutter/material.dart';

// The small heading above a group of settings, e.g. "Theme", "Preferences".
class SettingsLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SettingsLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: color ?? theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
