import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/page_title.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_dialog.dart';

class SnippetsPage extends StatelessWidget {
  const SnippetsPage({super.key});

  static const route = "/snippets";

  Future<void> _add(BuildContext context) async {
    final result = await SnippetDialog.show(context);
    if (result != null && context.mounted) {
      context.read<SnippetListBloc>().add(SnippetAdded(result));
    }
  }

  Future<void> _edit(BuildContext context, Snippet snippet) async {
    final result = await SnippetDialog.show(context, snippet: snippet);
    if (result != null && context.mounted) {
      context.read<SnippetListBloc>().add(SnippetUpdated(result));
    }
  }

  Future<void> _delete(BuildContext context, Snippet snippet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete snippet?"),
        content: Text("\"${snippet.label}\" will be permanently deleted."),
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
    if (confirmed == true && context.mounted) {
      context.read<SnippetListBloc>().add(SnippetDeleted(snippet.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text("New Snippet"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: BlocConsumer<SnippetListBloc, SnippetListState>(
            listenWhen: (_, current) => current.errorMessage != null,
            listener: (context, state) =>
                showAppSnackBar(context, state.errorMessage!, success: false),
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  const LargeHeaderSliver("Snippets"),
                  // A load failure must not read as an empty list, or the user
                  // recreates snippets over a store that is still there.
                  if (state.status == SnippetListStatus.failure)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _LoadFailed(),
                    )
                  else if (state.snippets.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      sliver: SliverList.separated(
                        itemCount: state.snippets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final snippet = state.snippets[index];
                          return _SnippetTile(
                            snippet: snippet,
                            onEdit: () => _edit(context, snippet),
                            onDelete: () => _delete(context, snippet),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SnippetTile extends StatelessWidget {
  final Snippet snippet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SnippetTile({
    required this.snippet,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(LucideIcons.zap, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snippet.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Hidden value",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Edit",
                icon: const Icon(LucideIcons.pencil, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: "Delete",
                icon: Icon(LucideIcons.trash2, size: 20, color: scheme.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 56,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text("Could not load snippets", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Your snippets are still stored. Try again, and do not add new "
            "ones until they appear.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                context.read<SnippetListBloc>().add(SnippetListLoaded()),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.zap, size: 64, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              "No snippets yet",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Save reusable text like tokens or commands, then paste them into any terminal with a tap.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
