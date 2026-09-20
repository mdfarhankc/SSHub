import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/name_prompt_dialog.dart';

// The file browser's app-bar actions, shared by every host of a file session.
// The cubit is passed explicitly so this works from the workspace app bar,
// which sits outside the session's provider.
List<Widget> buildSftpActions(
  BuildContext context,
  SftpCubit cubit,
  SftpState state,
) {
  final scheme = Theme.of(context).colorScheme;
  return [
    IconButton(
      tooltip: state.showHidden ? "Hide hidden files" : "Show hidden files",
      icon: Icon(state.showHidden ? LucideIcons.eye : LucideIcons.eyeOff),
      onPressed: cubit.toggleHidden,
    ),
    IconButton(
      tooltip: state.gridView ? "List view" : "Grid view",
      icon: Icon(state.gridView ? LucideIcons.list : LucideIcons.layoutGrid),
      onPressed: cubit.toggleGridView,
    ),
    IconButton(
      tooltip: state.searching ? "Close search" : "Search this folder",
      icon: Icon(
        LucideIcons.search,
        color: state.searching ? scheme.primary : null,
      ),
      onPressed: cubit.toggleSearch,
    ),
    IconButton(
      tooltip: state.selecting ? "Cancel selection" : "Select files",
      icon: Icon(
        LucideIcons.listChecks,
        color: state.selecting ? scheme.primary : null,
      ),
      onPressed: state.selecting ? cubit.exitSelection : cubit.enterSelection,
    ),
    IconButton(
      tooltip: state.readOnly ? "Read-only mode is on" : "Changes are allowed",
      icon: Icon(
        state.readOnly ? LucideIcons.lock : LucideIcons.lockOpen,
        color: state.readOnly ? scheme.primary : null,
      ),
      onPressed: () => _toggleReadOnly(context, cubit, state),
    ),
    if (!state.readOnly) ...[
      IconButton(
        tooltip: "New folder",
        icon: const Icon(LucideIcons.folderPlus),
        onPressed: () => _createFolder(context, cubit),
      ),
      IconButton(
        tooltip: "Upload a file",
        icon: const Icon(LucideIcons.fileUp),
        onPressed: state.transfer == null
            ? () => cubit.upload(
                confirmOverwrite: (name) => _confirmOverwrite(context, name),
              )
            : null,
      ),
      IconButton(
        tooltip: "Upload a folder",
        icon: const Icon(LucideIcons.folderUp),
        onPressed: state.transfer == null
            ? () => cubit.uploadFolder(
                confirmOverwrite: (name) => _confirmOverwrite(context, name),
              )
            : null,
      ),
    ],
    IconButton(
      tooltip: "Refresh",
      icon: const Icon(LucideIcons.refreshCw),
      onPressed: cubit.refresh,
    ),
    const SizedBox(width: 4),
  ];
}

Future<void> _toggleReadOnly(
  BuildContext context,
  SftpCubit cubit,
  SftpState state,
) async {
  if (!state.readOnly) {
    cubit.toggleReadOnly();
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Allow changes?"),
      content: const Text(
        "Uploading, renaming, creating folders and deleting will be turned "
        "on for every server until you switch read-only back on.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text("Allow"),
        ),
      ],
    ),
  );
  if (confirmed ?? false) cubit.toggleReadOnly();
}

Future<bool> _confirmOverwrite(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Replace file?"),
      content: Text(
        '"$name" already exists here. Uploading replaces it, and the copy on '
        'the server cannot be recovered.',
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
          child: const Text("Replace"),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _createFolder(BuildContext context, SftpCubit cubit) async {
  final name = await NamePromptDialog.show(
    context,
    title: "New folder",
    actionLabel: "Create",
  );
  if (name != null) await cubit.createDirectory(name);
}
