import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final result = await showDialog<({SshServer server, String? password})>(
      context: context,
      builder: (_) => ServerDialog(server: server),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ServerColors.resolve(server.colorValue, theme.colorScheme);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: _hovering ? 0.14 : 0.07),
            theme.colorScheme.surfaceContainer,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: _hovering ? accent : accent.withValues(alpha: 0.25),
            width: _hovering ? 1.5 : 1,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Icon(Icons.dns_outlined, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      server.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  "${server.username}@${server.host}:${server.port}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (server.description.isNotEmpty) ...[
                const SizedBox(height: 4),
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
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: onAccent,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        TerminalPage.route,
                        arguments: server,
                      );
                    },
                    icon: const Icon(Icons.terminal, size: 18),
                    label: const Text("Connect"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
