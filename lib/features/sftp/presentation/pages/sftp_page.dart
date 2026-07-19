import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/centered_message.dart';
import 'package:sshub/features/sftp/presentation/widgets/name_prompt_dialog.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_listing.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_path_bar.dart';
import 'package:sshub/features/sftp/presentation/widgets/transfer_bar.dart';

class SftpPage extends StatelessWidget {
  const SftpPage({super.key});

  static const route = "/sftp";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<SftpCubit, SftpState>(
      // A failed listing keeps the browser usable, so the reason is shown as a
      // snack bar rather than replacing the screen.
      listenWhen: (_, current) =>
          (current.errorMessage != null || current.noticeMessage != null) &&
          current.status == SftpStatus.ready,
      listener: (context, state) {
        final error = state.errorMessage;
        final notice = state.noticeMessage;
        if (error != null) showAppSnackBar(context, error, success: false);
        if (notice != null) showAppSnackBar(context, notice);
        context.read<SftpCubit>().clearMessages();
      },
      builder: (context, state) {
        final cubit = context.read<SftpCubit>();
        final ready = state.status == SftpStatus.ready;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cubit.server.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Files",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: ready
                ? [
                    IconButton(
                      tooltip: state.showHidden
                          ? "Hide hidden files"
                          : "Show hidden files",
                      icon: Icon(
                        state.showHidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                      onPressed: cubit.toggleHidden,
                    ),
                    IconButton(
                      tooltip: state.gridView ? "List view" : "Grid view",
                      icon: Icon(
                        state.gridView
                            ? LucideIcons.list
                            : LucideIcons.layoutGrid,
                      ),
                      onPressed: cubit.toggleGridView,
                    ),
                    IconButton(
                      tooltip: state.readOnly
                          ? "Read-only mode is on"
                          : "Changes are allowed",
                      icon: Icon(
                        state.readOnly
                            ? LucideIcons.lock
                            : LucideIcons.lockOpen,
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
                                confirmOverwrite: (name) =>
                                    _confirmOverwrite(context, name),
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
                  ]
                : null,
            bottom: ready
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(SftpPathBar.height),
                    child: SftpPathBar(state: state, cubit: cubit),
                  )
                : null,
          ),
          body: switch (state.status) {
            SftpStatus.connecting => const CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  SizedBox(height: 20),
                  Text("Opening a file session..."),
                ],
              ),
            ),
            SftpStatus.failure => CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.folderX, size: 56, color: scheme.error),
                  const SizedBox(height: 20),
                  Text(
                    "Could not open files",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? "",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    child: FilledButton.icon(
                      onPressed: cubit.connect,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text("Try Again"),
                    ),
                  ),
                ],
              ),
            ),
            SftpStatus.ready => Column(
              children: [
                if (state.busy) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  // The listing on screen belongs to the previous folder until
                  // the new one lands, so it fades rather than looking current.
                  child: AnimatedOpacity(
                    opacity: state.busy ? 0.5 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: state.busy,
                      child: SftpListing(state: state, cubit: cubit),
                    ),
                  ),
                ),
                if (state.transfer != null)
                  TransferBar(
                    transfer: state.transfer!,
                    onCancel: cubit.cancelTransfer,
                  ),
              ],
            ),
          },
        );
      },
    );
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
}
