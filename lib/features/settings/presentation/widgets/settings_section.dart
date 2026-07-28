import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/settings/presentation/sections/about_section.dart';
import 'package:sshub/features/settings/presentation/sections/appearance_section.dart';
import 'package:sshub/features/settings/presentation/sections/connections_section.dart';
import 'package:sshub/features/settings/presentation/sections/data_section.dart';
import 'package:sshub/features/settings/presentation/sections/files_section.dart';
import 'package:sshub/features/settings/presentation/sections/known_hosts_section.dart';
import 'package:sshub/features/settings/presentation/sections/security_section.dart';
import 'package:sshub/features/settings/presentation/sections/shortcuts_section.dart';

// One entry in the settings list. [body] is the detail content shown in the
// pane on desktop or the pushed page on a phone.
class SettingsSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final WidgetBuilder body;

  const SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.destructive = false,
  });
}

List<SettingsSection> buildSettingsSections() => [
  SettingsSection(
    icon: LucideIcons.palette,
    title: "Appearance",
    subtitle: "Theme, terminal font and size",
    body: (_) => const AppearanceSection(),
  ),
  SettingsSection(
    icon: LucideIcons.folder,
    title: "Files",
    subtitle: "Downloads and browser defaults",
    body: (_) => const FilesSection(),
  ),
  SettingsSection(
    icon: LucideIcons.network,
    title: "Connections",
    subtitle: "Defaults for new servers",
    body: (_) => const ConnectionsSection(),
  ),
  SettingsSection(
    icon: LucideIcons.keyboard,
    title: "Shortcuts",
    subtitle: "Customise keyboard shortcuts",
    body: (_) => const ShortcutsSection(),
  ),
  // App lock relies on the device biometric stack, which Linux lacks.
  if (!Platform.isLinux)
    SettingsSection(
      icon: LucideIcons.shieldCheck,
      title: "Security",
      subtitle: "App lock and secret reveals",
      body: (_) => const SecuritySection(),
    ),
  SettingsSection(
    icon: LucideIcons.fingerprint,
    title: "Known hosts",
    subtitle: "Remembered SSH host keys",
    body: (_) => const KnownHostsSection(),
  ),
  SettingsSection(
    icon: LucideIcons.database,
    title: "Data",
    subtitle: "Backup, restore and clear your data",
    body: (_) => const DataSection(),
  ),
  SettingsSection(
    icon: LucideIcons.info,
    title: "About",
    subtitle: "Version and updates",
    body: (_) => const AboutSection(),
  ),
];
