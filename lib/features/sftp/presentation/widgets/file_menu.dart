import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/widgets/context_menu_area.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/delete_confirm_dialog.dart';
import 'package:sshub/features/sftp/presentation/widgets/name_prompt_dialog.dart';

// The actions for one remote file, shared by the list and grid tiles so both
// open the same lifted menu. Rename and delete appear only when the session can
// write.
List<ContextMenuAction> fileMenuActions(
  BuildContext context,
  RemoteFile file,
  SftpCubit cubit, {
  required bool canWrite,
}) => [
  ContextMenuAction(
    icon: LucideIcons.download,
    label: file.isDirectory ? "Download folder" : "Download",
    onPressed: () => cubit.download(file),
  ),
  if (canWrite) ...[
    ContextMenuAction(
      icon: LucideIcons.filePen,
      label: "Rename",
      onPressed: () => _rename(context, file, cubit),
    ),
    ContextMenuAction(
      icon: LucideIcons.trash2,
      label: "Delete",
      destructive: true,
      onPressed: () => _delete(context, file, cubit),
    ),
  ],
];

Future<void> _rename(
  BuildContext context,
  RemoteFile file,
  SftpCubit cubit,
) async {
  if (!context.mounted) return;
  final name = await NamePromptDialog.show(
    context,
    title: "Rename",
    actionLabel: "Rename",
    initialValue: file.name,
  );
  if (name != null && name != file.name) await cubit.rename(file, name);
}

Future<void> _delete(
  BuildContext context,
  RemoteFile file,
  SftpCubit cubit,
) async {
  if (!context.mounted) return;
  if (await DeleteConfirmDialog.show(context, file)) {
    await cubit.delete(file);
  }
}
