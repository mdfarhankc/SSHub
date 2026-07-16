import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class TransferBar extends StatelessWidget {
  final SftpTransfer transfer;
  const TransferBar({super.key, required this.transfer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = transfer.fraction;
    final percent = fraction == null ? null : (fraction * 100).round();

    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    transfer.isUpload
                        ? LucideIcons.upload
                        : LucideIcons.download,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      transfer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    transfer.total > 0
                        ? "${formatBytes(transfer.transferred)} / ${formatBytes(transfer.total)}"
                        : formatBytes(transfer.transferred),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (percent != null) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 38,
                      child: Text(
                        "$percent%",
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: fraction, minHeight: 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
