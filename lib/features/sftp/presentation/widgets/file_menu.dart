import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/delete_confirm_dialog.dart';
import 'package:sshub/features/sftp/presentation/widgets/name_prompt_dialog.dart';

class FileMenu extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  final bool compact;
  const FileMenu({
    super.key,
    required this.file,
    required this.cubit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canWrite = !context.watch<SftpCubit>().state.readOnly;

    return PopupMenuButton<String>(
      tooltip: "File options",
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      onSelected: (action) => _onAction(context, action),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              const Icon(LucideIcons.download, size: 18),
              const SizedBox(width: 12),
              Text(file.isDirectory ? "Download folder" : "Download"),
            ],
          ),
        ),
        if (canWrite) ...[
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(LucideIcons.filePen, size: 18),
                SizedBox(width: 12),
                Text("Rename"),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 18, color: scheme.error),
                const SizedBox(width: 12),
                Text(
                  "Delete",
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 8),
        child: Icon(
          LucideIcons.ellipsis,
          size: compact ? 18 : 22,
          color: compact ? scheme.onSurfaceVariant : null,
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    switch (action) {
      case 'download':
        await cubit.download(file);
      case 'rename':
        final name = await NamePromptDialog.show(
          context,
          title: "Rename",
          actionLabel: "Rename",
          initialValue: file.name,
        );
        if (name != null && name != file.name) await cubit.rename(file, name);
      case 'delete':
        if (!context.mounted) return;
        if (await DeleteConfirmDialog.show(context, file)) {
          await cubit.delete(file);
        }
    }
  }
}
