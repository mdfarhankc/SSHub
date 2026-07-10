import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

class HomeHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final FocusNode? searchFocusNode;
  const HomeHeader({
    super.key,
    required this.onSearchChanged,
    this.searchFocusNode,
  });

  Future<void> _addServer(BuildContext context) async {
    final result = await ServerDialog.show(context);
    if (result != null && context.mounted) {
      context.read<ServerListBloc>().add(ServerAdded(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;

    final search = TextField(
      focusNode: searchFocusNode,
      onChanged: onSearchChanged,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        hintText: "Search your infrastructure...",
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );

    if (isMobile) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () => _addServer(context),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => _addServer(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text("Add Server"),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ],
    );
  }
}
