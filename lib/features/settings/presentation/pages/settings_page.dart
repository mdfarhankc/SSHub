import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/backup/backup_crypto.dart';

import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/export_options_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/passphrase_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Theme"),
                const SizedBox(height: 8),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text("System"),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text("Light"),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text("Dark"),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => cubit.updateThemeMode(s.first),
                ),
              ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Font family"),
                const SizedBox(height: 8),
                DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: settings.terminalFontFamily,
                  dropdownMenuEntries: [
                    for (final f in _fontFamilies)
                      DropdownMenuEntry(value: f, label: f),
                  ],
                  onSelected: (f) {
                    if (f != null) cubit.updateTerminalFontFamily(f);
                  },
                ),
              ],
            ),
          ),
          // Data
          const SettingsSectionHeader("Data"),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text("Export data"),
            subtitle: const Text(
              "Back up servers, passwords and settings to a file",
            ),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text("Import data"),
            subtitle: const Text("Restore servers and settings from a backup"),
            onTap: () => _importData(context),
          ),
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

  void _snack(BuildContext context, String message, {bool success = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: Theme.of(context).textTheme.labelLarge),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

  Future<void> _exportData(BuildContext context) async {
    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (_) => const ExportOptionsDialog(),
    );
    if (options == null || !context.mounted) return;

    final repo = context.read<BackupRepository>();
    try {
      final content = await repo.export(
        includeServers: options.includeServers,
        includeSettings: options.includeSettings,
        passphrase: options.passphrase,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "Save SSHub backup",
        fileName: options.passphrase != null
            ? "sshub-backup.json"
            : "sshub-backup-plain.json",
        type: FileType.custom,
        allowedExtensions: ["json"],
        bytes: utf8.encode(content),
      );
      if (path == null) return;
      if (!Platform.isAndroid && !Platform.isIOS) {
        await File(path).writeAsString(content);
      }
      if (context.mounted) _snack(context, "Backup exported");
    } catch (_) {
      if (context.mounted) _snack(context, "Export failed", success: false);
    }
  }

  Future<void> _importData(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select SSHub backup",
      type: FileType.custom,
      allowedExtensions: ["json"],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    final content = utf8.decode(bytes);

    String? passphrase;
    try {
      if (BackupCrypto.isEncrypted(content)) {
        passphrase = await showDialog<String>(
          context: context,
          builder: (_) => const PassphraseDialog(),
        );
        if (passphrase == null || !context.mounted) return;
      }
    } on BackupException catch (e) {
      if (context.mounted) _snack(context, e.message, success: false);
      return;
    }

    final repo = context.read<BackupRepository>();
    try {
      final count = await repo.import(content, passphrase);
      if (context.mounted) {
        context.read<SettingsCubit>().reload();
        context.read<ServerListBloc>().add(ServerListLoaded());
        _snack(context, "Imported $count servers");
      }
    } on BackupException catch (e) {
      if (context.mounted) _snack(context, e.message, success: false);
    } catch (_) {
      if (context.mounted) _snack(context, "Import failed", success: false);
    }
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
        context.read<ServerListBloc>().add(ServerListLoaded());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("All data cleared")));
      }
    }
  }
}
