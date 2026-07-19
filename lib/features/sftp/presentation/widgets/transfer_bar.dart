import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/format/elapsed.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class TransferBar extends StatelessWidget {
  final SftpTransfer transfer;
  final VoidCallback onCancel;
  const TransferBar({
    super.key,
    required this.transfer,
    required this.onCancel,
  });

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transfer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (transfer.detail != null)
                          Text(
                            transfer.detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
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
                  const SizedBox(width: 10),
                  Text(
                    formatElapsed(transfer.elapsed),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: AppTheme.mono,
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
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: "Stop transfer",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: onCancel,
                  ),
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
