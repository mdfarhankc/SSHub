import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/backup/backup_crypto.dart';
import 'package:sshub/core/theme/app_theme.dart';

import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/export_options_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/passphrase_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_card.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';
import 'package:sshub/features/settings/presentation/widgets/theme_selector.dart';
import 'package:sshub/features/settings/presentation/widgets/update_check_tile.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const route = "/settings";
  static const _fontFamilies = [
    "JetBrains Mono",
    "monospace",
    "Consolas",
    "Courier New",
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();
    final auth = context.read<LocalAuthService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                title: const Text(
                  "Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SettingsCard(
                      icon: Icons.palette_outlined,
                      title: "Appearance",
                      children: [
                        SettingsRow(
                          title: "App Theme",
                          subtitle:
                              "Choose between light, dark, or system theme.",
                          control: ThemeSelector(
                            value: settings.themeMode,
                            onChanged: cubit.updateThemeMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: Icons.terminal_outlined,
                      title: "Terminal",
                      children: [
                        SettingsRow(
                          title: "Font Family",
                          subtitle: "Select the typeface for the terminal.",
                          control: SizedBox(
                            width: 180,
                            child: DropdownMenu<String>(
                              expandedInsets: EdgeInsets.zero,
                              requestFocusOnTap: false,
                              initialSelection:
                                  _fontFamilies.contains(
                                    settings.terminalFontFamily,
                                  )
                                  ? settings.terminalFontFamily
                                  : _fontFamilies.first,
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onSelected: (f) {
                                if (f != null)
                                  cubit.updateTerminalFontFamily(f);
                              },
                              dropdownMenuEntries: _fontFamilies
                                  .map(
                                    (f) =>
                                        DropdownMenuEntry(value: f, label: f),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        SettingsRow(
                          title: "Font Size",
                          subtitle: "Adjust the terminal text size.",
                          stack: true,
                          trailing: Text(
                            "${settings.terminalFontSize.toInt()} pt",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          control: Slider(
                            value: settings.terminalFontSize,
                            min: 10,
                            max: 24,
                            divisions: 14,
                            onChanged: cubit.updateTerminalFontSize,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: Icons.security_outlined,
                      title: "Security",
                      children: [
                        SettingsRow(
                          title: "App Lock",
                          subtitle:
                              "Protect SSHub with biometric or device lock.",
                          keepInline: true,
                          control: Switch(
                            value: settings.appLockEnabled,
                            onChanged: (value) async {
                              if (value) {
                                cubit.enableAppLock();
                              } else if (await auth.authenticate(
                                "Disable app lock",
                              )) {
                                cubit.disableAppLock();
                              }
                            },
                          ),
                        ),
                        if (settings.appLockEnabled) ...[
                          const Divider(indent: 16, endIndent: 16),
                          SettingsRow(
                            title: "Lock Password Reveal",
                            subtitle:
                                "Authenticate before viewing saved passwords.",
                            keepInline: true,
                            control: Switch(
                              value: settings.lockPasswordReveal,
                              onChanged: cubit.updateLockPasswordReveal,
                            ),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          SettingsRow(
                            title: "Lock Snippet Reveal",
                            subtitle:
                                "Authenticate before viewing saved snippet values.",
                            keepInline: true,
                            control: Switch(
                              value: settings.lockSnippetReveal,
                              onChanged: cubit.updateLockSnippetReveal,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: Icons.backup_outlined,
                      title: "Backup & Restore",
                      description:
                          "Export or import your server configurations securely.",
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _exportData(context),
                                  icon: const Icon(Icons.upload_rounded),
                                  label: const Text("Export"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _importData(context),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text("Import"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: Icons.info_outline_rounded,
                      title: "About",
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  "assets/icon/icon_without_bg.png",
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SSHub",
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Version 2.0.0",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        const UpdateCheckTile(),
                        const Divider(indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Designed and built by",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Mohammed Farhan K C",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _openGithub(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.code_rounded,
                                  size: 20,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "github.com/mdfarhankc",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Danger Zone".toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: scheme.errorContainer.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: scheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _confirmClearAll(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Delete All Data",
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: scheme.error,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Wipe all servers and passwords permanently.",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.delete_forever_rounded,
                                color: scheme.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _openGithub(BuildContext context) async {
    final uri = Uri.parse("https://github.com/mdfarhankc");
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(context, "Could not open link", success: false);
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, "Could not open link", success: false);
      }
    }
  }

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
        includeSnippets: options.includeSnippets,
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
      await repo.import(content, passphrase);
      if (context.mounted) {
        context.read<SettingsCubit>().reload();
        context.read<ServerListBloc>().add(ServerListLoaded());
        context.read<SnippetListBloc>().add(SnippetListLoaded());
        _snack(context, "Backup restored");
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
