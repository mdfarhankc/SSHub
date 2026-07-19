import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/centered_message.dart';
import 'package:sshub/features/sftp/presentation/widgets/file_card.dart';
import 'package:sshub/features/sftp/presentation/widgets/file_tile.dart';

class SftpListing extends StatelessWidget {
  final SftpState state;
  final SftpCubit cubit;
  const SftpListing({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = state.visibleEntries;

    if (entries.isEmpty) {
      return CenteredMessage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.entries.isEmpty
                  ? "This folder is empty"
                  : "Only hidden files here",
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: state.gridView
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                // Fits a name wrapped to two lines. The menu row, icon and
                // padding are a fixed 96; only the text grows with the scale.
                mainAxisExtent: 96 + MediaQuery.textScalerOf(context).scale(48),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  FileCard(file: entries[index], cubit: cubit),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  FileTile(file: entries[index], cubit: cubit),
            ),
    );
  }
}
