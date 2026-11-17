import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';

// Chooses whether a snippet or workflow is global or tied to one server.
// null means global.
class ScopeDropdown extends StatelessWidget {
  final String? serverId;
  final ValueChanged<String?> onChanged;
  const ScopeDropdown({
    super.key,
    required this.serverId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServerListBloc>().state.servers;
    // The current value must match an item, so cover a server that no longer
    // exists (e.g. restored from a backup) with a fallback entry.
    final orphan =
        serverId != null && !servers.any((s) => s.id == serverId);
    return DropdownButtonFormField<String?>(
      initialValue: serverId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: "Available on",
        prefixIcon: Icon(LucideIcons.server, size: 18),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text("All servers (global)"),
        ),
        for (final server in servers)
          DropdownMenuItem(
            value: server.id,
            child: Text(server.label, overflow: TextOverflow.ellipsis),
          ),
        if (orphan)
          DropdownMenuItem(value: serverId, child: const Text("Removed server")),
      ],
      onChanged: onChanged,
    );
  }
}
