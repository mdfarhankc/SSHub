import 'package:flutter/material.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/core/widgets/page_title.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < Responsive.mobileMaxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PageTitle(
              "Settings",
              base: narrow
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 2),
            Text(
              "Manage your application preferences and security.",
              style:
                  (narrow
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }
}
