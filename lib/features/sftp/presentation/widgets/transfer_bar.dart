import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/format/elapsed.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class TransferBar extends StatelessWidget {
  final SftpTransfer? transfer;
  final List<QueuedTransfer> queue;
  final List<PausedTransfer> paused;
  final SftpCubit cubit;
  const TransferBar({
    super.key,
    required this.transfer,
    required this.queue,
    required this.paused,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasRowAbove = transfer != null || queue.isNotEmpty;
    final showSummary = queue.isNotEmpty || paused.isNotEmpty;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (transfer != null)
                _ActiveRow(
                  transfer: transfer!,
                  onStop: cubit.cancelTransfer,
                  onPause: transfer!.pausable
                      ? cubit.pauseActiveTransfer
                      : null,
                )
              else if (queue.isNotEmpty)
                const _PreparingRow(),
              if (showSummary) ...[
                if (hasRowAbove) const SizedBox(height: 8),
                _SummaryChip(
                  queued: queue.length,
                  paused: paused.length,
                  onTap: () => _openSheet(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showBlurredBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _TransferSheet(cubit: cubit),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  final SftpTransfer transfer;
  final VoidCallback onStop;
  final VoidCallback? onPause;
  const _ActiveRow({
    required this.transfer,
    required this.onStop,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = transfer.fraction;
    final percent = fraction == null ? null : (fraction * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              transfer.isUpload ? LucideIcons.upload : LucideIcons.download,
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
            if (onPause != null)
              IconButton(
                tooltip: "Pause transfer",
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.pause, size: 18),
                onPressed: onPause,
              ),
            IconButton(
              tooltip: "Stop transfer",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: onStop,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: fraction, minHeight: 5),
        ),
      ],
    );
  }
}

// Shown in the brief gap between one queued transfer finishing and the next
// starting, so the bar does not blink out.
class _PreparingRow extends StatelessWidget {
  const _PreparingRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.hourglass, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Text(
              "Starting next transfer...",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(minHeight: 5),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int queued;
  final int paused;
  final VoidCallback onTap;
  const _SummaryChip({
    required this.queued,
    required this.paused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parts = [
      if (queued > 0) "$queued queued",
      if (paused > 0) "$paused paused",
    ].join("  ·  ");
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              LucideIcons.listOrdered,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              "Manage",
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferSheet extends StatelessWidget {
  final SftpCubit cubit;
  const _TransferSheet({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return BlocBuilder<SftpCubit, SftpState>(
      bloc: cubit,
      builder: (context, state) {
        final active = state.transfer;
        final paused = state.paused;
        final queue = state.queue;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Transfers",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (active != null)
                      _ActiveTile(
                        transfer: active,
                        onStop: cubit.cancelTransfer,
                        onPause: active.pausable
                            ? cubit.pauseActiveTransfer
                            : null,
                      ),
                    for (final p in paused)
                      _PausedTile(
                        item: p,
                        onResume: () => cubit.resume(p.id),
                        onCancel: () => cubit.cancelPaused(p.id),
                      ),
                    for (final q in queue)
                      _QueuedTile(
                        item: q,
                        onRemove: () => cubit.removeQueued(q.id),
                      ),
                    if (active == null && paused.isEmpty && queue.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No transfers.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (queue.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: cubit.clearQueue,
                    child: const Text("Clear queue"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveTile extends StatelessWidget {
  final SftpTransfer transfer;
  final VoidCallback onStop;
  final VoidCallback? onPause;
  const _ActiveTile({
    required this.transfer,
    required this.onStop,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 4),
      dense: true,
      leading: Icon(
        transfer.isUpload ? LucideIcons.upload : LucideIcons.download,
        size: 18,
        color: scheme.primary,
      ),
      title: Text(
        transfer.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text("In progress"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPause != null)
            IconButton(
              tooltip: "Pause",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.pause, size: 18),
              onPressed: onPause,
            ),
          IconButton(
            tooltip: "Stop",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.x, size: 18),
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

class _PausedTile extends StatelessWidget {
  final PausedTransfer item;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  const _PausedTile({
    required this.item,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = item.total > 0
        ? "Paused  ·  ${formatBytes(item.bytesDone)} / ${formatBytes(item.total)}"
        : "Paused";
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 4),
      dense: true,
      leading: Icon(
        item.isUpload ? LucideIcons.upload : LucideIcons.download,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(detail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Resume",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.play, size: 18),
            onPressed: onResume,
          ),
          IconButton(
            tooltip: "Cancel",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.x, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _QueuedTile extends StatelessWidget {
  final QueuedTransfer item;
  final VoidCallback onRemove;
  const _QueuedTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 4),
      dense: true,
      leading: Icon(
        item.isUpload ? LucideIcons.upload : LucideIcons.download,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: const Text("Queued"),
      trailing: IconButton(
        tooltip: "Remove",
        visualDensity: VisualDensity.compact,
        icon: const Icon(LucideIcons.x, size: 18),
        onPressed: onRemove,
      ),
    );
  }
}
