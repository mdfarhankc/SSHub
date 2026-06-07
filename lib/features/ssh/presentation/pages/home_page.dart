import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_card.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const route = "/home";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SSHub"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, SettingsPage.route);
              if (context.mounted) {
                context.read<ServerListBloc>().add(ServerListLoaded());
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<ServerListBloc, ServerListState>(
        listenWhen: (previous, current) => current.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          switch (state.status) {
            case (ServerListStatus.loading || ServerListStatus.initial):
              return Center(child: CircularProgressIndicator());
            case (ServerListStatus.success):
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 184,
                    ),
                    itemCount: state.servers.length,
                    itemBuilder: (_, i) =>
                        ServerCard(server: state.servers[i]),
                  );
                },
              );
            case (ServerListStatus.failure):
              return Center(child: Text("Failed to load servers"));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await showDialog<({SshServer server, String? password})>(
                context: context,
                builder: (_) => const ServerDialog(),
              );
          if (result != null && context.mounted) {
            context.read<ServerListBloc>().add(
              ServerAdded(result.server, result.password!),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Server"),
      ),
    );
  }
}
