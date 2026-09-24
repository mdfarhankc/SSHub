import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/theme/app_colors.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/context_menu_area.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/workspace_page.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';
import 'package:sshub/features/stats/presentation/widgets/server_stats_sheet.dart';

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
  final _menuKey = GlobalKey<ContextMenuAreaState>();

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

  void _browseFiles() {
    context.read<WorkspaceSessionsCubit>().openFiles(server);
    Navigator.pushNamed(context, WorkspacePage.route);
  }

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
    // Tapping a server that is already open focuses its terminal tab instead of
    // stacking a second connection to the same host.
    context.read<WorkspaceSessionsCubit>().openTerminal(server);
    Navigator.pushNamed(context, WorkspacePage.route);
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

    return ContextMenuArea(
      key: _menuKey,
      actions: [
        ContextMenuAction(
          icon: LucideIcons.terminal,
          label: "Open Terminal",
          onPressed: _connect,
        ),
        ContextMenuAction(
          icon: LucideIcons.folderOpen,
          label: "Browse Files",
          onPressed: _browseFiles,
        ),
        ContextMenuAction(
          icon: LucideIcons.activity,
          label: "Server info",
          onPressed: () => ServerStatsSheet.show(context, server),
        ),
        ContextMenuAction(
          icon: LucideIcons.pencil,
          label: "Edit Settings",
          onPressed: _edit,
        ),
        ContextMenuAction(
          icon: LucideIcons.rotateCcwKey,
          label: "Forget Host Key",
          onPressed: _forgetHostKey,
        ),
        ContextMenuAction(
          icon: LucideIcons.trash2,
          label: "Remove Server",
          onPressed: _confirmDelete,
          destructive: true,
        ),
      ],
      child: MouseRegion(
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
                          IconButton(
                            tooltip: "Browse files",
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(LucideIcons.folderOpen, size: 20),
                            onPressed: _browseFiles,
                          ),
                          _buildMenuButton(),
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
                      if (server.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _TagChips(tags: server.tags, accent: accent),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.reachability != Reachability.unknown)
                            Flexible(child: _StatusPill(widget.reachability))
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _lastSeen(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
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
      ),
    );
  }

  // Opens the same lifted menu as long-press and right-click.
  Widget _buildMenuButton() {
    return IconButton(
      tooltip: "Server options",
      visualDensity: VisualDensity.compact,
      icon: const Icon(LucideIcons.ellipsis, size: 22),
      onPressed: () => _menuKey.currentState?.open(),
    );
  }
}

// A single clipped line of tag pills. Extra tags collapse into a "+N" pill so
// the card keeps its fixed height regardless of how many tags a server carries.
class _TagChips extends StatelessWidget {
  final List<String> tags;
  final Color accent;
  const _TagChips({required this.tags, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxShown = 3;
    final shown = tags.take(maxShown).toList();
    final extra = tags.length - shown.length;

    Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Flexible(child: pill(shown[i])),
        ],
        if (extra > 0) ...[const SizedBox(width: 6), pill("+$extra")],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Reachability reachability;
  const _StatusPill(this.reachability);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    // Offline is red rather than grey, so it reads at a glance and does not
    // blend into the card.
    final (color, label) = switch (reachability) {
      Reachability.online => (scheme.primary, "Online"),
      Reachability.offline => (scheme.error, "Offline"),
      Reachability.checking => (colors.warning, "Checking"),
      Reachability.unknown => (scheme.onSurfaceVariant, "Unknown"),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
