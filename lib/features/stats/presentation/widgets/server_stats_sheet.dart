import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/core/widgets/section_header.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/stats/domain/entities/server_stats.dart';
import 'package:sshub/features/stats/presentation/cubit/server_stats_cubit.dart';
import 'package:sshub/features/stats/presentation/widgets/process_list_sheet.dart';

class ServerStatsSheet extends StatelessWidget {
  final SshServer server;
  // When set, the sheet shares an already-connected cubit rather than opening
  // its own, so the workspace bar's live data shows instantly.
  final ServerStatsCubit? existing;
  const ServerStatsSheet({super.key, required this.server, this.existing});

  static Future<void> show(
    BuildContext context,
    SshServer server, {
    ServerStatsCubit? cubit,
  }) => showBlurredBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ServerStatsSheet(server: server, existing: cubit),
  );

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    return existing != null
        ? BlocProvider.value(value: existing!, child: content)
        : BlocProvider(create: (_) => ServerStatsCubit(server, sl()), child: content);
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        server.host,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: AppTheme.mono,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: BlocBuilder<ServerStatsCubit, ServerStatsState>(
                  builder: (context, state) => _body(context, state),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _body(BuildContext context, ServerStatsState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = state.stats;

    if (stats == null && state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.serverCog, size: 44, color: scheme.error),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: context.read<ServerStatsCubit>().refresh,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.stale) ...[
          Row(
            children: [
              Icon(
                LucideIcons.refreshCw,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                "Reconnecting, showing last reading",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (stats.os.isNotEmpty) _meta(theme, LucideIcons.info, stats.os),
            if (stats.kernel.isNotEmpty)
              _meta(theme, LucideIcons.cpu, stats.kernel),
            _meta(theme, LucideIcons.clock, _uptime(stats.uptimeSeconds)),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(icon: LucideIcons.gauge, title: "CPU"),
        const SizedBox(height: 10),
        _UsageRow(
          label: "Usage",
          fraction: (stats.cpuPercent ?? 0) / 100,
          detail: stats.cpuPercent == null
              ? "..."
              : "${stats.cpuPercent!.round()}%",
          color: scheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          "${stats.cores} cores  ·  load ${stats.load1.toStringAsFixed(2)}, "
          "${stats.load5.toStringAsFixed(2)}, ${stats.load15.toStringAsFixed(2)}",
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(icon: LucideIcons.memoryStick, title: "Memory"),
        const SizedBox(height: 10),
        _UsageRow(
          label: "RAM",
          fraction: stats.memFraction,
          detail:
              "${formatBytes(stats.memUsed)} / ${formatBytes(stats.memTotal)}",
          color: scheme.primary,
        ),
        if (stats.swapTotal > 0) ...[
          const SizedBox(height: 10),
          _UsageRow(
            label: "Swap",
            fraction: stats.swapFraction,
            detail:
                "${formatBytes(stats.swapUsed)} / ${formatBytes(stats.swapTotal)}",
            color: scheme.tertiary,
          ),
        ],
        if (stats.disks.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader(icon: LucideIcons.hardDrive, title: "Storage"),
          const SizedBox(height: 10),
          for (final disk in stats.disks) ...[
            _UsageRow(
              label: disk.mount,
              fraction: disk.fraction,
              detail:
                  "${formatBytes(disk.used)} / ${formatBytes(disk.total)}",
              color: scheme.primary,
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (stats.gpu != null) ...[
          const SizedBox(height: 12),
          const SectionHeader(icon: LucideIcons.zap, title: "GPU"),
          const SizedBox(height: 10),
          _UsageRow(
            label: "Usage",
            fraction: stats.gpu!.utilPercent / 100,
            detail: "${stats.gpu!.utilPercent}%",
            color: scheme.primary,
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: "VRAM",
            fraction: stats.gpu!.memFraction,
            detail:
                "${stats.gpu!.memUsedMb} / ${stats.gpu!.memTotalMb} MB",
            color: scheme.primary,
          ),
        ],
        if (stats.processes.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  icon: LucideIcons.list,
                  title: "Top processes",
                ),
              ),
              TextButton(
                onPressed: () => ProcessListSheet.show(context, server),
                child: const Text("View all"),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final process in stats.processes.take(5))
            _ProcessRow(process: process),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  String _uptime(int seconds) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (d > 0) return "up ${d}d ${h}h";
    if (h > 0) return "up ${h}h ${m}m";
    return "up ${m}m";
  }
}

class _ProcessRow extends StatelessWidget {
  final ProcessInfo process;
  const _ProcessRow({required this.process});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metric = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFamily: AppTheme.mono,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              process.command,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text("${process.cpuPercent.toStringAsFixed(0)}% cpu", style: metric),
          const SizedBox(width: 12),
          Text("${process.memPercent.toStringAsFixed(0)}% mem", style: metric),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final double fraction;
  final String detail;
  final Color color;
  const _UsageRow({
    required this.label,
    required this.fraction,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = fraction.clamp(0.0, 1.0).toDouble();
    // Warn as a resource fills up.
    final barColor = value >= 0.9
        ? scheme.error
        : (value >= 0.75 ? Colors.orange : color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFamily: AppTheme.mono,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}
