import 'package:flutter/material.dart';

import 'package:sshub/core/theme/app_colors.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

// Single source of truth for how a file session's status reads, mirroring
// terminalStatusOf so the tab strip treats both kinds the same way.
(Color, String) sftpStatusOf(BuildContext context, SftpState state) {
  final colors = AppColors.of(context);
  return switch (state.status) {
    SftpStatus.connecting => (colors.warning, "Opening"),
    SftpStatus.ready => (colors.success, "Ready"),
    SftpStatus.failure => (Theme.of(context).colorScheme.error, "Failed"),
  };
}
