import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

class DangerZoneSection extends StatelessWidget {
  const DangerZoneSection({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear all data?"),
        content: const Text(
          "Servers, stored passwords and keys, snippets, and remembered host "
          "keys will be permanently deleted. Your settings are kept.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Unavailable passes through, so the dialog stays the base gate. A refused
    // prompt does not.
    final result = await sl<LocalAuthService>().authenticate("Delete all data");
    if (result == AuthResult.failed || !context.mounted) return;
    // Fingerprints outlive the servers that earned them, so a later server on
    // the same host and port would be trusted without a prompt.
    await sl<SshRepository>().clearAll();
    await sl<SnippetRepository>().clearAll();
    await sl<KnownHostsDatasource>().clear();
    if (!context.mounted) return;
    context.read<ServerListBloc>().add(ServerListLoaded());
    context.read<SnippetListBloc>().add(SnippetListLoaded());
    showAppSnackBar(context, "All data cleared");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Delete all data",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Wipe every server, key, snippet and remembered host key.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => _confirmClearAll(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
