import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/file_menu.dart';
import 'package:sshub/features/sftp/presentation/widgets/open_remote_file.dart';

class FileTile extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const FileTile({super.key, required this.file, required this.cubit});

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
      onTap: () => openRemoteFile(context, file, cubit),
      trailing: FileMenu(file: file, cubit: cubit),
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
