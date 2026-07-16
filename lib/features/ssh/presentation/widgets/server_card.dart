import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/theme/app_colors.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/presentation/pages/sftp_page.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/terminal_page.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

enum _CardAction { browse, edit, forgetHostKey, delete }

class ServerCard extends StatefulWidget {
  final SshServer server;
  final Reachability reachability;
  const ServerCard({
    super.key,
    required this.server,
    this.reachability = Reachability.unknown,
  });

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool _hovering = false;

  SshServer get server => widget.server;

  Future<void> _edit() async {
    final result = await ServerDialog.show(context, server: server);
    if (result != null && mounted) {
      context.read<ServerListBloc>().add(ServerUpdated(result));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete server?"),
        content: Text(
          '"${server.label}" and its stored password will be removed.',
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
    if (confirmed == true && mounted) {
      context.read<ServerListBloc>().add(ServerDeleted(server.id));
    }
  }

  void _browseFiles() =>
      Navigator.pushNamed(context, SftpPage.route, arguments: server);

  // A rebuilt server legitimately presents a new host key, which verification
  // would otherwise refuse forever.
  Future<void> _forgetHostKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Forget host key?"),
        content: Text(
          "SSHub will trust whatever key ${server.host} presents next time, "
          "the way it did on the first connection.\n\nOnly do this if you know "
          "the server changed, such as after a rebuild. If it changed on its "
          "own, the warning may be real and someone could be impersonating it.",
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
            child: const Text("Forget"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await sl<KnownHostsDatasource>().forget(server.host, server.port);
    if (mounted) {
      showAppSnackBar(context, "Host key forgotten for ${server.host}");
    }
  }

  void _connect() {
    // "Last seen" is stamped only on a real connection, not a failed attempt.
    // Tapping a server that is already open focuses its tab instead of
    // stacking a second connection to the same host.
    context.read<TerminalSessionsCubit>().openOrFocus(server);
    Navigator.pushNamed(context, TerminalPage.route);
  }

  String _lastSeen() {
    final t = server.lastConnectedAt;
    if (t == null) return "Not connected yet";
    final d = DateTime.now().difference(t);
    final ago = d.inSeconds < 60
        ? "just now"
        : d.inMinutes < 60
        ? "${d.inMinutes}m ago"
        : d.inHours < 24
        ? "${d.inHours}h ago"
        : "${d.inDays}d ago";
    return "Last seen: $ago";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ServerColors.resolve(server.colorValue, scheme);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: _hovering
                ? accent.withValues(alpha: 0.5)
                : scheme.outlineVariant,
            width: _hovering ? 2 : 1,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.cardShadow(theme.brightness),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _connect,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.terminal,
                                size: 20,
                                color: accent,
                              ),
                            ),
                            if (widget.reachability != Reachability.unknown)
                              Positioned(
                                right: -3,
                                bottom: -3,
                                child: _StatusDot(widget.reachability),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                server.host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontFamily: AppTheme.mono,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildPopupMenu(scheme),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (server.description.isNotEmpty)
                      Text(
                        server.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: Text(
                            _lastSeen(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 18,
                          color: _hovering ? accent : scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(ColorScheme scheme) {
    return PopupMenuButton<_CardAction>(
      tooltip: "Server options",
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      elevation: 3,
      onSelected: (action) {
        switch (action) {
          case .browse:
            _browseFiles();
          case .edit:
            _edit();
          case .forgetHostKey:
            _forgetHostKey();
          case .delete:
            _confirmDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: .browse,
          child: Row(
            children: [
              Icon(LucideIcons.folderOpen, size: 18),
              SizedBox(width: 12),
              Text("Browse Files"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: .edit,
          child: Row(
            children: [
              Icon(LucideIcons.pencil, size: 18),
              SizedBox(width: 12),
              Text("Edit Settings"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: .forgetHostKey,
          child: Row(
            children: [
              Icon(LucideIcons.rotateCcwKey, size: 18),
              SizedBox(width: 12),
              Text("Forget Host Key"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: .delete,
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: scheme.error),
              const SizedBox(width: 12),
              Text(
                "Remove Server",
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: const Icon(LucideIcons.ellipsis, size: 22),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Reachability reachability;
  const _StatusDot(this.reachability);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (color, label) = switch (reachability) {
      Reachability.online => (scheme.primary, "Online"),
      Reachability.offline => (scheme.onSurfaceVariant, "Offline"),
      Reachability.checking => (colors.warning, "Checking..."),
      Reachability.unknown => (Colors.transparent, ""),
    };
    return Tooltip(
      message: label,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 2.5),
        ),
      ),
    );
  }
}
