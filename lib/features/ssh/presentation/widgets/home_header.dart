import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

class HomeHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  const HomeHeader({super.key, required this.onSearchChanged});

  Future<void> _addServer(BuildContext context) async {
    final result = await ServerDialog.show(context);
    if (result != null && context.mounted) {
      context.read<ServerListBloc>().add(
        ServerAdded(result.server, result.password!),
      );
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.pushNamed(context, SettingsPage.route);
    if (context.mounted) {
      context.read<ServerListBloc>().add(ServerListLoaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final search = SizedBox(
      width: 240,
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          hintText: "Search servers...",
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: () => _addServer(context),
      icon: const Icon(Icons.add),
      label: const Text("Add Server"),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );

    final settingsButton = FilledButton(
      onPressed: () => _openSettings(context),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: const Icon(Icons.settings),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < Responsive.mobileMaxWidth;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "My Servers",
              style:
                  (narrow
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage and connect to your infrastructure.",
              style:
                  (narrow
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: addButton),
                  const SizedBox(width: 8),
                  settingsButton,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            search,
            const SizedBox(width: 12),
            addButton,
            const SizedBox(width: 12),
            settingsButton,
          ],
        );
      },
    );
  }
}
