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

class FileCard extends StatefulWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const FileCard({super.key, required this.file, required this.cubit});

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
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
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return ContextMenuArea(
      key: _menuKey,
      borderRadius: radius,
      // No lifted menu while selecting; a tap toggles the tick instead.
      actions: selecting
          ? const []
          : fileMenuActions(context, file, widget.cubit, canWrite: canWrite),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          onTap: selecting
              ? () => widget.cubit.toggleSelected(file.path)
              : () => openRemoteFile(context, file, widget.cubit),
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
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
                    child: selecting
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              selected
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circle,
                              size: 18,
                              color: selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          )
                        : IconButton(
                            tooltip: "File options",
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              LucideIcons.ellipsis,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () => _menuKey.currentState?.open(),
                          ),
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
      ),
    );
  }
}
