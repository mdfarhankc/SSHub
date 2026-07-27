import 'package:flutter/material.dart';

import 'package:sshub/features/settings/presentation/widgets/settings_section.dart';

// The drill-down page shown on a phone after tapping a settings category.
class SettingsDetailPage extends StatelessWidget {
  final SettingsSection section;
  const SettingsDetailPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [section.body(context)],
        ),
      ),
    );
  }
}
