import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/export_options_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/passphrase_dialog.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_card.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

class BackupCard extends StatelessWidget {
  const BackupCard({super.key});

  Future<void> _export(BuildContext context) async {
    final options = await showModalBottomSheet<ExportOptions>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ExportOptionsDialog(),
    );
    if (options == null || !context.mounted) return;
    context.read<BackupCubit>().export(options);
  }

  Future<void> _onState(BuildContext context, BackupState state) async {
    switch (state.status) {
      case BackupStatus.working:
        showAppLoadingSnackBar(context, state.message ?? "Working...");
      case BackupStatus.needsPassphrase:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final passphrase = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const PassphraseDialog(),
        );
        if (!context.mounted) return;
        final cubit = context.read<BackupCubit>();
        if (passphrase == null) {
          cubit.cancelImport();
        } else {
          cubit.submitPassphrase(passphrase);
        }
      case BackupStatus.exported:
        showAppSnackBar(context, "Backup exported");
      case BackupStatus.imported:
        context.read<SettingsCubit>().reload();
        context.read<ServerListBloc>().add(ServerListLoaded());
        context.read<SnippetListBloc>().add(SnippetListLoaded());
        showAppSnackBar(context, "Backup restored");
      case BackupStatus.failure:
        showAppSnackBar(
          context,
          state.message ?? "Something went wrong",
          success: false,
        );
      case BackupStatus.idle:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BackupCubit, BackupState>(
      listener: _onState,
      child: SettingsCard(
        icon: Icons.backup_outlined,
        title: "Backup & Restore",
        description: "Export or import your server configurations securely.",
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export(context),
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text("Export"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<BackupCubit>().pickAndImport(),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text("Import"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
