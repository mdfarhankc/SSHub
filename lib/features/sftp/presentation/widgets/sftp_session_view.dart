import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';
import 'package:sshub/features/sftp/presentation/widgets/centered_message.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_listing.dart';
import 'package:sshub/features/sftp/presentation/widgets/sftp_search_field.dart';
import 'package:sshub/features/sftp/presentation/widgets/transfer_bar.dart';

// One file browser tab's body. The session lives in the workspace cubit; this
// only renders it. The path bar and toolbar actions live in the workspace app
// bar, so this is just the listing, its transfer bar, and error surfacing.
class SftpSessionView extends StatelessWidget {
  final SftpCubit cubit;
  const SftpSessionView({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<SftpCubit>.value(
      value: cubit,
      child: BlocConsumer<SftpCubit, SftpState>(
        bloc: cubit,
        // A failed listing keeps the browser usable, so the reason is shown as
        // a snack bar rather than replacing the screen.
        listenWhen: (_, current) =>
            (current.errorMessage != null || current.noticeMessage != null) &&
            current.status == SftpStatus.ready,
        listener: (context, state) {
          final error = state.errorMessage;
          final notice = state.noticeMessage;
          if (error != null) showAppSnackBar(context, error, success: false);
          if (notice != null) showAppSnackBar(context, notice);
          cubit.clearMessages();
        },
        builder: (context, state) {
          return switch (state.status) {
            SftpStatus.connecting => const CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  SizedBox(height: 20),
                  Text("Opening a file session..."),
                ],
              ),
            ),
            SftpStatus.failure => CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.folderX, size: 56, color: scheme.error),
                  const SizedBox(height: 20),
                  Text(
                    "Could not open files",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? "",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    child: FilledButton.icon(
                      onPressed: cubit.connect,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text("Try Again"),
                    ),
                  ),
                ],
              ),
            ),
            SftpStatus.ready => Column(
              children: [
                if (state.busy) const LinearProgressIndicator(minHeight: 3),
                if (state.searching)
                  SftpSearchField(cubit: cubit, state: state),
                Expanded(
                  // The listing on screen belongs to the previous folder until
                  // the new one lands, so it fades rather than looking current.
                  child: AnimatedOpacity(
                    opacity: state.busy ? 0.5 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: state.busy,
                      child: SftpListing(state: state, cubit: cubit),
                    ),
                  ),
                ),
                if (state.transfer != null)
                  TransferBar(
                    transfer: state.transfer!,
                    onCancel: cubit.cancelTransfer,
                  ),
              ],
            ),
          };
        },
      ),
    );
  }
}
