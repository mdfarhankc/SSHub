import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/file_menu.dart';
import 'package:sshub/features/sftp/presentation/widgets/open_remote_file.dart';

class FileCard extends StatelessWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const FileCard({super.key, required this.file, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () => openRemoteFile(context, file, cubit),
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
                  child: FileMenu(file: file, cubit: cubit, compact: true),
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
