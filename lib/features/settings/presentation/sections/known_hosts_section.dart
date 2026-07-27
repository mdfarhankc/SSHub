import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';

class KnownHostsSection extends StatefulWidget {
  const KnownHostsSection({super.key});

  @override
  State<KnownHostsSection> createState() => _KnownHostsSectionState();
}

class _KnownHostsSectionState extends State<KnownHostsSection> {
  final _datasource = sl<KnownHostsDatasource>();
  late Future<List<KnownHostEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _datasource.listAll();
  }

  void _reload() => setState(() => _future = _datasource.listAll());

  Future<void> _forget(KnownHostEntry entry) async {
    await _datasource.forget(entry.host, entry.port);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<List<KnownHostEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final hosts = snapshot.data ?? const [];
        if (hosts.isEmpty) {
          return _EmptyState();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "SSHub trusts these host keys. Forget one to be asked to "
                "verify it again on the next connection.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < hosts.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                    _HostRow(
                      entry: hosts[i],
                      onForget: () => _forget(hosts[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HostRow extends StatelessWidget {
  final KnownHostEntry entry;
  final VoidCallback onForget;
  const _HostRow({required this.entry, required this.onForget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = [
      if (entry.type != null) entry.type!,
      entry.fingerprint,
    ].join("  ");

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Icon(LucideIcons.server, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.port == 22 ? entry.host : "${entry.host}:${entry.port}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: "Forget",
            visualDensity: VisualDensity.compact,
            icon: Icon(LucideIcons.trash2, size: 18, color: scheme.error),
            onPressed: onForget,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: 40,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No remembered hosts",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Host keys are remembered the first time you connect to a server.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
