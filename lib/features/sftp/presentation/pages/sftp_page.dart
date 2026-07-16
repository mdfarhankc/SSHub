import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/file_viewer_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/pages/file_viewer_page.dart';
import 'package:sshub/features/sftp/presentation/widgets/name_prompt_dialog.dart';
import 'package:sshub/features/sftp/presentation/widgets/transfer_bar.dart';

void _open(BuildContext context, RemoteFile file, SftpCubit cubit) {
  if (file.isDirectory) {
    cubit.openDirectory(file);
    return;
  }
  final session = cubit.session;
  if (session == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(create: (_) => FileViewerCubit(session, file)),
        ],
        child: const FileViewerPage(),
      ),
    ),
  );
}

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
                        onPressed: state.transfer == null ? cubit.upload : null,
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
                    preferredSize: const Size.fromHeight(45),
                    child: _PathBar(state: state, cubit: cubit),
                  )
                : null,
          ),
          body: switch (state.status) {
            SftpStatus.connecting => const _Centered(
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
            SftpStatus.failure => _Centered(
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
                if (state.busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _Listing(state: state, cubit: cubit),
                ),
                if (state.transfer != null)
                  TransferBar(transfer: state.transfer!),
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

  Future<void> _createFolder(BuildContext context, SftpCubit cubit) async {
    final name = await NamePromptDialog.show(
      context,
      title: "New folder",
      actionLabel: "Create",
    );
    if (name != null) await cubit.createDirectory(name);
  }
}

class _PathBar extends StatelessWidget {
  final SftpState state;
  final SftpCubit cubit;
  const _PathBar({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: 45,
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: "Up one folder",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.arrowUp, size: 18),
            onPressed: state.isRoot ? null : cubit.goUp,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                state.path,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: AppTheme.mono,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Listing extends StatelessWidget {
  final SftpState state;
  final SftpCubit cubit;
  const _Listing({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = state.visibleEntries;

    if (entries.isEmpty) {
      return _Centered(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.entries.isEmpty
                  ? "This folder is empty"
                  : "Only hidden files here",
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: state.gridView
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                // Fits a name wrapped to two lines. The menu row, icon and
                // padding are a fixed 96; only the text grows with the scale.
                mainAxisExtent: 96 + MediaQuery.textScalerOf(context).scale(48),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _FileCard(file: entries[index], cubit: cubit),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _FileTile(file: entries[index], cubit: cubit),
            ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const _FileCard({required this.file, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () => _open(context, file, cubit),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Held open when there is no menu, so icons stay in line.
              SizedBox(
                height: 30,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _FileMenu(file: file, cubit: cubit, compact: true),
                ),
              ),
              Icon(
                file.isLink
                    ? LucideIcons.link
                    : file.isDirectory
                    ? LucideIcons.folder
                    : LucideIcons.file,
                size: 32,
                color: file.isDirectory
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: file.isDirectory
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                file.isDirectory ? "Folder" : formatBytes(file.size),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const _FileTile({required this.file, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        file.isLink
            ? LucideIcons.link
            : file.isDirectory
            ? LucideIcons.folder
            : LucideIcons.file,
        color: file.isDirectory ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: file.isDirectory ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        _subtitle(file),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _open(context, file, cubit),
      trailing: _FileMenu(file: file, cubit: cubit),
    );
  }

  static String _subtitle(RemoteFile file) {
    final parts = <String>[
      if (file.isDirectory) "Folder" else formatBytes(file.size),
      if (file.modified != null) _formatDate(file.modified!),
    ];
    return parts.join("  ·  ");
  }

  static String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}

class _FileMenu extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  final bool compact;
  const _FileMenu({
    required this.file,
    required this.cubit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canWrite = !context.watch<SftpCubit>().state.readOnly;
    final canDownload = !file.isDirectory;

    // A folder in read-only mode has nothing to offer, and an empty popup
    // would assert.
    if (!canWrite && !canDownload) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: "File options",
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      onSelected: (action) => _onAction(context, action),
      itemBuilder: (_) => [
        if (canDownload)
          const PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(LucideIcons.download, size: 18),
                SizedBox(width: 12),
                Text("Download"),
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
        final confirmed = await _confirmDelete(context);
        if (confirmed) await cubit.delete(file);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(file.isDirectory ? "Delete folder?" : "Delete file?"),
        content: Text(
          file.isDirectory
              ? '"${file.name}" must be empty to be deleted. This cannot be undone.'
              : '"${file.name}" will be deleted from the server. This cannot be undone.',
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
    return result ?? false;
  }
}

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}
