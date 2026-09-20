import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/context_menu_area.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/file_menu.dart';
import 'package:sshub/features/sftp/presentation/widgets/open_remote_file.dart';

class FileTile extends StatefulWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const FileTile({super.key, required this.file, required this.cubit});

  @override
  State<FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
  final _menuKey = GlobalKey<ContextMenuAreaState>();

  RemoteFile get file => widget.file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canWrite = context.select<SftpCubit, bool>((c) => !c.state.readOnly);
    final selecting = context.select<SftpCubit, bool>((c) => c.state.selecting);
    final selected = context.select<SftpCubit, bool>(
      (c) => c.state.selected.contains(file.path),
    );

    return ContextMenuArea(
      key: _menuKey,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      // No lifted menu while selecting; a tap toggles the tick instead.
      actions: selecting
          ? const []
          : fileMenuActions(context, file, widget.cubit, canWrite: canWrite),
      // A solid surface so the lifted copy has a backing over the blur.
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surface,
        child: ListTile(
          leading: selecting
              ? Checkbox(
                  value: selected,
                  onChanged: (_) => widget.cubit.toggleSelected(file.path),
                )
              : Icon(
                  file.isLink
                      ? LucideIcons.link
                      : file.isDirectory
                      ? LucideIcons.folder
                      : LucideIcons.file,
                  color: file.isDirectory
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
          title: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: file.isDirectory
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            _subtitle(file),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          onTap: selecting
              ? () => widget.cubit.toggleSelected(file.path)
              : () => openRemoteFile(context, file, widget.cubit),
          trailing: selecting
              ? null
              : IconButton(
                  tooltip: "File options",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.ellipsis, size: 22),
                  onPressed: () => _menuKey.currentState?.open(),
                ),
        ),
      ),
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
