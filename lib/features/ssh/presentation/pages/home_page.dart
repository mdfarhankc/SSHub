import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/widgets/home_header.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const route = "/home";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = "";

  List<SshServer> _filter(List<SshServer> servers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return servers;
    return servers
        .where(
          (s) =>
              s.label.toLowerCase().contains(q) ||
              s.host.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: HomeHeader(
              onSearchChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: BlocConsumer<ServerListBloc, ServerListState>(
              listenWhen: (previous, current) => current.errorMessage != null,
              listener: (context, state) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              },
              builder: (context, state) {
                switch (state.status) {
                  case (ServerListStatus.loading || ServerListStatus.initial):
                    return const Center(child: CircularProgressIndicator());
                  case (ServerListStatus.success):
                    final servers = _filter(state.servers);
                    if (servers.isEmpty) {
                      return _EmptyState(searching: _query.trim().isNotEmpty);
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width < 600
                            ? 1
                            : width < 900
                            ? 2
                            : width < 1300
                            ? 3
                            : 4;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 184,
                              ),
                          itemCount: servers.length,
                          itemBuilder: (_, i) => ServerCard(server: servers[i]),
                        );
                      },
                    );
                  case (ServerListStatus.failure):
                    return const Center(child: Text("Failed to load servers"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off : Icons.dns_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            searching ? "No matching servers" : "No servers yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? "Try a different name, host or description."
                : "Add a server to get started.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
