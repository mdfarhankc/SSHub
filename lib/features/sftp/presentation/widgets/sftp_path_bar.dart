import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class SftpPathBar extends StatelessWidget {
  static const height = 45.0;

  final SftpState state;
  final SftpCubit cubit;
  const SftpPathBar({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: "Up one folder",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.arrowUp, size: 18),
            onPressed: state.isRoot ? null : cubit.goUp,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                state.path,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: AppTheme.mono,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
