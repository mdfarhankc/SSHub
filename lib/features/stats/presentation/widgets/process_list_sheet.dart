import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/stats/domain/entities/server_stats.dart';
import 'package:sshub/features/stats/presentation/cubit/process_list_cubit.dart';

// The full process list for a server, sorted by CPU, fetched on demand with a
// Load more button rather than polled.
class ProcessListSheet extends StatelessWidget {
  final SshServer server;
  const ProcessListSheet({super.key, required this.server});

  static Future<void> show(BuildContext context, SshServer server) =>
      showBlurredBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ProcessListSheet(server: server),
      );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProcessListCubit(server, sl()),
    child: _content(context),
  );

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
              Icon(LucideIcons.list, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Processes on ${server.label}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BlocBuilder<ProcessListCubit, ProcessListState>(
                builder: (context, state) => IconButton(
                  tooltip: "Refresh",
                  visualDensity: VisualDensity.compact,
                  onPressed: state.loading
                      ? null
                      : context.read<ProcessListCubit>().refresh,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: BlocBuilder<ProcessListCubit, ProcessListState>(
              builder: (context, state) => _body(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ProcessListState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state.processes.isEmpty && state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.processes.isEmpty && state.error != null) {
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
                onPressed: context.read<ProcessListCubit>().refresh,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final process in state.processes)
            _ProcessTile(process: process),
          const SizedBox(height: 8),
          if (state.hasMore)
            Center(
              child: state.loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: context.read<ProcessListCubit>().loadMore,
                      child: const Text("Load more"),
                    ),
            ),
          Text(
            "Sorted by CPU  ·  ${state.processes.length} shown",
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProcessTile extends StatelessWidget {
  final ProcessInfo process;
  const _ProcessTile({required this.process});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFamily: AppTheme.mono,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            process.command,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text("pid ${process.pid}", style: mono),
              const SizedBox(width: 14),
              Text("${process.cpuPercent.toStringAsFixed(0)}% cpu", style: mono),
              const SizedBox(width: 14),
              Text(_memory(process), style: mono),
            ],
          ),
        ],
      ),
    );
  }

  String _memory(ProcessInfo p) {
    final rss = p.rssKb;
    if (rss != null) return formatBytes(rss * 1024);
    return "${p.memPercent.toStringAsFixed(0)}% mem";
  }
}
