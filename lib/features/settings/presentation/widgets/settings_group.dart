import 'package:flutter/material.dart';

import 'package:sshub/features/settings/presentation/widgets/settings_label.dart';

// A grouped card of rows, without a title. The section title comes from the
// detail pane or the drill-down app bar instead.
class SettingsGroup extends StatelessWidget {
  final String? label;
  final String? description;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    this.label,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) SettingsLabel(label!),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}
