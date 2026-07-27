import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/core/theme/server_colors.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_session.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';

// Server list for the workspace "+" button, so a new tab can be opened without
// leaving the session you are already in. Each server can start a terminal or a
// file browser.
class ServerPickerSheet extends StatelessWidget {
  final void Function(SshServer server, WorkspaceKind kind) onSelected;
  const ServerPickerSheet({super.key, required this.onSelected});

  static Future<void> show(
    BuildContext context, {
    required void Function(SshServer server, WorkspaceKind kind) onSelected,
  }) => showBlurredBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => ServerPickerSheet(onSelected: onSelected),
  );

  // Opens the chosen server as a new tab. A second session to an already open
  // host is intentional here: choosing "+" means "another session".
  static void openSession(BuildContext context) {
    final sessions = context.read<WorkspaceSessionsCubit>();
    show(
      context,
      onSelected: (server, kind) => switch (kind) {
        WorkspaceKind.terminal => sessions.openTerminal(
          server,
          focusExisting: false,
        ),
        WorkspaceKind.files => sessions.openFiles(server, focusExisting: false),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: BlocBuilder<ServerListBloc, ServerListState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.server, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      "Open a session",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (state.servers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.server,
                        size: 48,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text("No servers yet", style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        "Add a server from the home screen to open it here.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.servers.length,
                    itemBuilder: (context, index) {
                      final server = state.servers[index];
                      final accent = ServerColors.resolve(
                        server.colorValue,
                        scheme,
                      );
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.server,
                            size: 18,
                            color: accent,
                          ),
                        ),
                        title: Text(
                          server.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${server.username}@${server.host}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFamily: AppTheme.mono,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "Terminal",
                              icon: const Icon(LucideIcons.terminal, size: 20),
                              onPressed: () => _pick(
                                context,
                                server,
                                WorkspaceKind.terminal,
                              ),
                            ),
                            IconButton(
                              tooltip: "Files",
                              icon: const Icon(LucideIcons.folder, size: 20),
                              onPressed: () =>
                                  _pick(context, server, WorkspaceKind.files),
                            ),
                          ],
                        ),
                        // Tapping the row defaults to a terminal.
                        onTap: () =>
                            _pick(context, server, WorkspaceKind.terminal),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _pick(BuildContext context, SshServer server, WorkspaceKind kind) {
    onSelected(server, kind);
    Navigator.pop(context);
  }
}
