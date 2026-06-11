import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/backup/backup_crypto.dart';
import 'package:sshub/core/theme/app_theme.dart';

import 'package:sshub/features/settings/domain/entities/app_settings.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/export_options_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/passphrase_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_card.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_header.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';
import 'package:sshub/features/settings/presentation/widgets/theme_selector.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SettingsHeader(),
          const SizedBox(height: 16),

          SettingsCard(
            icon: Icons.palette_outlined,
            title: "Appearance",
            children: [
              SettingsRow(
                title: "App Theme",
                subtitle: "Select your preferred color mode.",
                control: ThemeSelector(
                  value: settings.themeMode,
                  onChanged: cubit.updateThemeMode,
                ),
              ),
            ],
          ),

          SettingsCard(
            icon: Icons.terminal_outlined,
            title: "Terminal Environment",
            children: [
              SettingsRow(
                title: "Font Family",
                subtitle: "Used for terminal output.",
                control: SizedBox(
                  width: 220,
                  child: DropdownMenu<String>(
                    expandedInsets: EdgeInsets.zero,
                    requestFocusOnTap: false,
                    initialSelection: settings.terminalFontFamily,
                    leadingIcon: const Icon(
                      Icons.font_download_outlined,
                      size: 20,
                    ),
                    textStyle: TextStyle(
                      fontFamily: settings.terminalFontFamily,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    menuStyle: MenuStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    dropdownMenuEntries: [
                      for (final f in _fontFamilies)
                        DropdownMenuEntry(
                          value: f,
                          label: f,
                          style: MenuItemButton.styleFrom(
                            textStyle: TextStyle(fontFamily: f),
                          ),
                        ),
                    ],
                    onSelected: (f) {
                      if (f != null) cubit.updateTerminalFontFamily(f);
                    },
                  ),
                ),
              ),
              const Divider(height: 8),
              SettingsRow(
                title: "Font Size",
                subtitle: "Adjust terminal text size.",
                stack: true,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${settings.terminalFontSize.toStringAsFixed(0)}px",
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                control: Row(
                  children: [
                    const Icon(Icons.text_decrease, size: 18),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: settings.terminalFontSize,
                          min: 10,
                          max: 24,
                          divisions: 14,
                          label: settings.terminalFontSize.toStringAsFixed(0),
                          onChanged: cubit.updateTerminalFontSize,
                        ),
                      ),
                    ),
                    const Icon(Icons.text_increase, size: 26),
                  ],
                ),
              ),
            ],
          ),

          SettingsCard(
            icon: Icons.lock_outline,
            title: "Authentication & Security",
            children: [
              SettingsRow(
                title: "Require App Lock",
                subtitle: "Prompt for authentication when opening SSHub.",
                keepInline: true,
                control: Switch(
                  value: settings.appLockEnabled,
                  onChanged: cubit.updateAppLock,
                ),
              ),
              if (settings.appLockEnabled) ...[
                const Divider(height: 8),
                SettingsRow(
                  title: "Lock Password Reveal",
                  subtitle: "Require authentication to view saved passwords.",
                  keepInline: true,
                  control: Switch(
                    value: settings.lockPasswordReveal,
                    onChanged: cubit.updateLockPasswordReveal,
                  ),
                ),
              ],
            ],
          ),

          SettingsCard(
            icon: Icons.storage_outlined,
            title: "Data Management",
            description:
                "Export your configurations for backup, or import from "
                "another device. Danger zone actions are at the bottom.",
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final export = FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _exportData(context),
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text("Export Data"),
                  );
                  final import = FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _importData(context),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text("Import Data"),
                  );
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [export, const SizedBox(height: 12), import],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: export),
                      const SizedBox(width: 12),
                      Expanded(child: import),
                    ],
                  );
                },
              ),
            ],
          ),

          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final info = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Danger Zone",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Permanently remove all servers and stored passwords.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  final button = FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                    ),
                    onPressed: () => _confirmClearAll(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete All Data"),
                  );
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [info, const SizedBox(height: 16), button],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: 16),
                      button,
                    ],
                  );
                },
              ),
            ),
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
