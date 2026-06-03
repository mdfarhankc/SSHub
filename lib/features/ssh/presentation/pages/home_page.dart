import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ssh_manager/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:ssh_manager/features/ssh/presentation/widgets/server_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const route = "/home";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ServerListBloc, ServerListState>(
        builder: (context, state) {
          switch (state.status) {
            case (ServerListStatus.loading || ServerListStatus.initial):
              return Center(child: CircularProgressIndicator());
            case (ServerListStatus.success):
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: state.servers.length,
                itemBuilder: (_, i) => ServerCard(server: state.servers[i]),
              );
            case (ServerListStatus.failure):
              return Center(child: Text("Failed to load servers"));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text("Add Server"),
      ),
    );
  }
}
