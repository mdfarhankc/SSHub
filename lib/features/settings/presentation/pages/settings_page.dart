import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const route = "/settings";
  static const _fontFamilies = [
    "Cascadia Mono",
    "monospace",
    "Consolas",
    "Courier New",
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme
          const SettingsSectionHeader("Appearance"),
          ListTile(
            title: const Text("Theme"),
            trailing: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text("System"),
                ),
                ButtonSegment(value: AppThemeMode.light, label: Text("Light")),
                ButtonSegment(value: AppThemeMode.dark, label: Text("Dark")),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => cubit.updateThemeMode(s.first),
            ),
          ),
          // Terminal
          const SettingsSectionHeader("Terminal"),
          ListTile(
            title: const Text("Font size"),
            subtitle: Slider(
              value: settings.terminalFontSize,
              min: 10,
              max: 24,
              divisions: 14,
              label: settings.terminalFontSize.toStringAsFixed(0),
              onChanged: cubit.updateTerminalFontSize,
            ),
            trailing: Text(settings.terminalFontSize.toStringAsFixed(0)),
          ),
          ListTile(
            title: const Text("Font family"),
            trailing: DropdownMenu<String>(
              initialSelection: settings.terminalFontFamily,
              dropdownMenuEntries: [
                for (final f in _fontFamilies)
                  DropdownMenuEntry(value: f, label: f),
              ],
              onSelected: (f) {
                if (f != null) cubit.updateTerminalFontFamily(f);
              },
            ),
          ),
          // Data
          const SettingsSectionHeader("Data"),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              "Clear all data",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text("Removes all servers and stored passwords"),
            onTap: () => _confirmClearAll(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear all data?"),
        content: const Text(
          "All servers and their stored passwords will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SshRepository>().clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("All data cleared")));
      }
    }
  }
}
