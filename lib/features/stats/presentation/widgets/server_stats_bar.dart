import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/stats/presentation/cubit/server_stats_cubit.dart';
import 'package:sshub/features/stats/presentation/widgets/server_stats_sheet.dart';

// A compact live strip of a server's CPU, memory and disk use for the top of a
// connected workspace on wide screens. Tapping it opens the full sheet, sharing
// its connection.
class ServerStatsBar extends StatefulWidget {
  static const height = 34.0;
  final SshServer server;
  const ServerStatsBar({super.key, required this.server});

  @override
  State<ServerStatsBar> createState() => _ServerStatsBarState();
}

class _ServerStatsBarState extends State<ServerStatsBar> {
  late final ServerStatsCubit _cubit = ServerStatsCubit(widget.server, sl());

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider.value(
      value: _cubit,
      child: Material(
        color: scheme.surface,
        child: InkWell(
          onTap: () =>
              ServerStatsSheet.show(context, widget.server, cubit: _cubit),
          child: Container(
            height: ServerStatsBar.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: BlocBuilder<ServerStatsCubit, ServerStatsState>(
              builder: (context, state) => _row(context, state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ServerStatsState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = state.stats;

    if (stats == null) {
      return Row(
        children: [
          Icon(LucideIcons.activity, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            state.error ?? "Reading server info...",
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final topDisk = stats.disks.isEmpty ? null : stats.disks.first;
    return Row(
      children: [
        _stat(theme, LucideIcons.gauge, "CPU", stats.cpuPercent),
        const SizedBox(width: 16),
        _stat(theme, LucideIcons.memoryStick, "RAM", stats.memFraction * 100),
        if (topDisk != null) ...[
          const SizedBox(width: 16),
          _stat(theme, LucideIcons.hardDrive, "Disk", topDisk.fraction * 100),
        ],
        if (stats.gpu != null) ...[
          const SizedBox(width: 16),
          _stat(
            theme,
            LucideIcons.zap,
            "GPU",
            stats.gpu!.utilPercent.toDouble(),
          ),
        ],
        const Spacer(),
        if (state.stale) ...[
          Icon(
            LucideIcons.refreshCw,
            size: 12,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
        ],
        Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _stat(ThemeData theme, IconData icon, String label, double? percent) {
    final scheme = theme.colorScheme;
    final value = percent?.clamp(0, 100).round();
    final color = value == null
        ? scheme.onSurfaceVariant
        : (value >= 90
              ? scheme.error
              : (value >= 75 ? Colors.orange : scheme.primary));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          "$label ${value == null ? '--' : '$value%'}",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
