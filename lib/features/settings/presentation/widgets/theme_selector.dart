import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/widgets/segmented_selector.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';

class ThemeSelector extends StatelessWidget {
  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;
  const ThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SegmentedSelector<AppThemeMode>(
    value: value,
    onChanged: onChanged,
    shrinkWrap: true,
    options: const [
      (AppThemeMode.system, LucideIcons.monitor, "System"),
      (AppThemeMode.light, LucideIcons.sun, "Light"),
      (AppThemeMode.dark, LucideIcons.moon, "Dark"),
    ],
  );
}
