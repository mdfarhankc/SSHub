import 'package:flutter/material.dart';

import 'package:sshub/features/settings/presentation/sections/backup_section.dart';
import 'package:sshub/features/settings/presentation/sections/danger_zone_section.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_label.dart';

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsLabel("Backup"),
        const BackupSection(),
        const SizedBox(height: 36),
        SettingsLabel("Danger zone", color: scheme.error),
        const DangerZoneSection(),
      ],
    );
  }
}
