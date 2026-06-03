import 'package:flutter/material.dart';

import 'package:ssh_manager/features/ssh/domain/entities/ssh_server.dart';

class ServerCard extends StatelessWidget {
  final SshServer server;
  const ServerCard({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(server.label, style: theme.textTheme.titleMedium),
              Text(
                "${server.username}@${server.host}:${server.port}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Align(
                alignment: .bottomRight,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text("Connect"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
