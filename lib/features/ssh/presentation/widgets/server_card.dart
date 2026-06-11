import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/pages/terminal_page.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

enum _CardAction { edit, delete }

class ServerCard extends StatefulWidget {
  final SshServer server;
  const ServerCard({super.key, required this.server});

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool _hovering = false;

  SshServer get server => widget.server;

  Future<void> _edit() async {
    final result = await ServerDialog.show(context, server: server);
    if (result != null && mounted) {
      context.read<ServerListBloc>().add(
        ServerUpdated(result.server, result.password),
      );
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

  void _connect() {
    context.read<ServerListBloc>().add(
      ServerUpdated(server.copyWith(lastConnectedAt: DateTime.now()), null),
    );
    Navigator.pushNamed(context, TerminalPage.route, arguments: server);
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
    final accent = ServerColors.resolve(server.colorValue, theme.colorScheme);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: _hovering
                ? theme.colorScheme.outline
                : theme.colorScheme.outlineVariant,
            width: _hovering ? 1.5 : 1,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                crossAxisAlignment: .start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Icon(Icons.dns_outlined, size: 22, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          server.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: .w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                server.host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "monospace",
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_CardAction>(
                    tooltip: "Options",
                    position: .under,
                    onSelected: (action) {
                      switch (action) {
                        case .edit:
                          _edit();
                        case .delete:
                          _confirmDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: .edit, child: Text("Edit")),
                      PopupMenuItem(value: .delete, child: Text("Delete")),
                    ],
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.more_vert, size: 20),
                    ),
                  ),
                ],
              ),
              if (server.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    server.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _lastSeen(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _connect,
                    child: const Row(
                      mainAxisSize: .min,
                      children: [
                        Text("Connect"),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
