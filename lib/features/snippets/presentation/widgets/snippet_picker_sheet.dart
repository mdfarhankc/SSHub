import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';

class SnippetPickerSheet extends StatelessWidget {
  final ValueChanged<Snippet> onSelected;
  const SnippetPickerSheet({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: BlocBuilder<SnippetListBloc, SnippetListState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.zap, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      "Snippets",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pushNamed(SnippetsPage.route);
                      },
                      icon: const Icon(LucideIcons.settings2, size: 18),
                      label: const Text("Manage"),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (state.snippets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: 48,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No snippets yet",
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add tokens or commands to paste them here.",
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
                    itemCount: state.snippets.length,
                    itemBuilder: (context, index) {
                      final snippet = state.snippets[index];
                      return ListTile(
                        leading: Icon(
                          LucideIcons.clipboardPaste,
                          color: scheme.primary,
                        ),
                        title: Text(snippet.label),
                        onTap: () {
                          onSelected(snippet);
                          Navigator.pop(context);
                        },
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
}
