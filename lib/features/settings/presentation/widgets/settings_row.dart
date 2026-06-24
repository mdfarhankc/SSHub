import 'package:flutter/material.dart';

class SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget control;
  // Optional widget pinned to the end of the text row (e.g. a value chip).
  final Widget? trailing;
  // Force the control onto its own line below the text (sliders, full inputs).
  final bool stack;
  // Keep the control on the right at every width (switches, toggles).
  final bool keepInline;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.control,
    this.trailing,
    this.stack = false,
    this.keepInline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final textRow = trailing == null
        ? text
        : Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              trailing!,
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (keepInline) {
            return Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                control,
              ],
            );
          }
          if (stack || constraints.maxWidth < 450) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [textRow, const SizedBox(height: 16), control],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 24),
              control,
            ],
          );
        },
      ),
    );
  }
}
