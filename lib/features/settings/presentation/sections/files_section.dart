import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_group.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';

class FilesSection extends StatelessWidget {
  const FilesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          label: "Downloads",
          description: "Where files and folders from the browser are saved.",
          children: [
            SettingsRow(
              title: "Download folder",
              subtitle:
                  settings.downloadDirectory ??
                  "Using the system downloads folder.",
              stack: true,
              control: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _choose(context, cubit),
                      icon: const Icon(LucideIcons.folderOpen, size: 18),
                      label: const Text("Change"),
                    ),
                  ),
                  if (settings.downloadDirectory != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => cubit.updateDownloadDirectory(null),
                        child: const Text("Reset"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SettingsGroup(
          label: "Browser defaults",
          description: "How the file browser opens for a new server.",
          children: [
            SettingsRow(
              title: "Read-only by default",
              subtitle: "Block changes until you unlock a server's browser.",
              keepInline: true,
              control: Switch(
                value: settings.sftpReadOnly,
                onChanged: cubit.updateSftpReadOnly,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Show hidden files",
              subtitle: "Reveal dotfiles in the listing.",
              keepInline: true,
              control: Switch(
                value: settings.sftpShowHidden,
                onChanged: cubit.updateSftpShowHidden,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Grid view",
              subtitle: "Open the browser as a grid instead of a list.",
              keepInline: true,
              control: Switch(
                value: settings.sftpGridView,
                onChanged: cubit.updateSftpGridView,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, SettingsCubit cubit) async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose a download folder",
    );
    if (picked == null) return;
    final writable = await _isWritable(picked);
    if (!context.mounted) return;
    if (!writable) {
      showAppSnackBar(
        context,
        "SSHub cannot save to that folder. Try one inside your own storage.",
        success: false,
      );
      return;
    }
    cubit.updateDownloadDirectory(picked);
  }

  // Scoped storage rejects writes outside app dirs, so probe first.
  static Future<bool> _isWritable(String path) async {
    try {
      final probe = File("$path/.sshub_write_check");
      await probe.writeAsString("");
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
