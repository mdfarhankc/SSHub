import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

class DangerZone extends StatelessWidget {
  const DangerZone({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear all data?"),
        content: const Text(
          "All servers and their stored passwords will be permanently deleted.",
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
    // Auth passes through where it is unavailable, so the dialog stays the base gate.
    final authed = await sl<LocalAuthService>().authenticate("Delete all data");
    if (!authed || !context.mounted) return;
    await sl<SshRepository>().clearAll();
    if (!context.mounted) return;
    context.read<ServerListBloc>().add(ServerListLoaded());
    showAppSnackBar(context, "All data cleared");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                "Danger Zone".toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
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
                      "Wipe all servers and passwords permanently.",
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
        ),
      ],
    );
  }
}
