import 'package:flutter/material.dart';
import 'package:sshub/core/widgets/section_header.dart';

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final List<Widget> children;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SectionHeader(icon: icon, title: title),
        ),
        Card(
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
