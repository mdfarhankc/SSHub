import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

// Shown above the listing while selection mode is on: the count and the batch
// actions for the ticked files.
class SftpSelectionBar extends StatelessWidget {
  final SftpCubit cubit;
  final SftpState state;
  const SftpSelectionBar({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = state.selected.length;
    final canDownload = count > 0 && state.transfer == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: "Cancel selection",
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: cubit.exitSelection,
          ),
          Text(
            count == 0 ? "Select files" : "$count selected",
            style: theme.textTheme.titleSmall,
          ),
          const Spacer(),
          TextButton(
            onPressed: cubit.selectAllVisible,
            child: const Text("All"),
          ),
          IconButton(
            tooltip: "Download",
            icon: const Icon(LucideIcons.download),
            onPressed: canDownload ? cubit.downloadSelected : null,
          ),
          if (!state.readOnly)
            IconButton(
              tooltip: "Delete",
              icon: const Icon(LucideIcons.trash2),
              color: scheme.error,
              onPressed: count > 0 ? () => _confirmDelete(context, count) : null,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Delete $count ${count == 1 ? 'item' : 'items'}?"),
        content: const Text(
          "The selected files and folders will be removed from the server and "
          "cannot be recovered.",
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
    if (confirmed ?? false) await cubit.deleteSelected();
  }
}
