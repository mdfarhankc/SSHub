import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/context_menu_area.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/snippets/presentation/widgets/snippet_dialog.dart';
import 'package:uuid/uuid.dart';

class SnippetsPage extends StatefulWidget {
  const SnippetsPage({super.key});

  static const route = "/snippets";

  @override
  State<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends State<SnippetsPage> {
  final _searchController = TextEditingController();
  String _query = "";

  bool get _searching => _query.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final result = await SnippetDialog.show(context);
    if (result != null && mounted) {
      context.read<SnippetListBloc>().add(SnippetAdded(result));
    }
  }

  Future<void> _edit(Snippet snippet) async {
    final result = await SnippetDialog.show(context, snippet: snippet);
    if (result != null && mounted) {
      context.read<SnippetListBloc>().add(SnippetUpdated(result));
    }
  }

  void _duplicate(Snippet snippet) {
    context.read<SnippetListBloc>().add(
      SnippetAdded(
        Snippet(
          id: const Uuid().v7(),
          label: "${snippet.label} copy",
          value: snippet.value,
          type: snippet.type,
        ),
      ),
    );
  }

  void _togglePin(Snippet snippet) {
    context.read<SnippetListBloc>().add(
      SnippetUpdated(snippet.copyWith(pinned: !snippet.pinned)),
    );
  }

  Future<void> _delete(Snippet snippet) async {
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
    if (confirmed == true && mounted) {
      context.read<SnippetListBloc>().add(SnippetDeleted(snippet.id));
    }
  }

  void _reorderWithinType(SnippetType type, int oldIndex, int newIndex) {
    final all = context.read<SnippetListBloc>().state.snippets;
    final sub = [
      for (final s in all)
        if (s.type == type) s,
    ];
    if (newIndex > oldIndex) newIndex -= 1;
    sub.insert(newIndex, sub.removeAt(oldIndex));
    var i = 0;
    final rebuilt = [for (final s in all) s.type == type ? sub[i++] : s];
    context.read<SnippetListBloc>().add(SnippetsReordered(rebuilt));
  }

  List<Snippet> _filter(List<Snippet> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final s in all)
        if (s.label.toLowerCase().contains(q) ||
            (!s.isSecret && s.value.toLowerCase().contains(q)))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Snippets")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
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
              if (state.status == SnippetListStatus.failure) {
                return const _LoadFailed();
              }
              if (state.snippets.isEmpty) {
                return _EmptyState(onAdd: _add);
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: _SearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  Expanded(child: _twoColumns(state.snippets)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _twoColumns(List<Snippet> all) {
    final secrets = [
      for (final s in all)
        if (s.isSecret) s,
    ];
    final commands = [
      for (final s in all)
        if (!s.isSecret) s,
    ];
    final shownSecrets = _searching ? _filter(secrets) : secrets;
    final shownCommands = _searching ? _filter(commands) : commands;
    if (_searching && shownSecrets.isEmpty && shownCommands.isEmpty) {
      return const _NoMatches();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _typeColumn(
              SnippetType.secret,
              "Secrets",
              LucideIcons.keyRound,
              shownSecrets,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _typeColumn(
              SnippetType.command,
              "Commands",
              LucideIcons.terminal,
              shownCommands,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeColumn(
    SnippetType type,
    String title,
    IconData icon,
    List<Snippet> shown,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColumnHeader(icon: icon, title: title, count: shown.length),
        const SizedBox(height: 8),
        Expanded(
          child: shown.isEmpty
              ? _EmptyColumn(searching: _searching)
              : _searching
              ? ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _tileFor(shown[index], index, false),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  buildDefaultDragHandles: false,
                  itemCount: shown.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderWithinType(type, oldIndex, newIndex),
                  proxyDecorator: (child, _, _) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(shown[index].id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _tileFor(shown[index], index, true),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tileFor(Snippet snippet, int index, bool reorderable) => _SnippetTile(
    key: ValueKey("tile-${snippet.id}"),
    snippet: snippet,
    index: index,
    reorderable: reorderable,
    onEdit: () => _edit(snippet),
    onDuplicate: () => _duplicate(snippet),
    onTogglePin: () => _togglePin(snippet),
    onDelete: () => _delete(snippet),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search snippets",
        prefixIcon: const Icon(LucideIcons.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged("");
                },
              ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _SnippetTile extends StatefulWidget {
  final Snippet snippet;
  final int index;
  final bool reorderable;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  const _SnippetTile({
    super.key,
    required this.snippet,
    required this.index,
    required this.reorderable,
    required this.onEdit,
    required this.onDuplicate,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  State<_SnippetTile> createState() => _SnippetTileState();
}

class _SnippetTileState extends State<_SnippetTile> {
  final _menuKey = GlobalKey<ContextMenuAreaState>();

  Snippet get snippet => widget.snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSecret = snippet.isSecret;

    return ContextMenuArea(
      key: _menuKey,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      actions: [
        ContextMenuAction(
          icon: LucideIcons.pencil,
          label: "Edit",
          onPressed: widget.onEdit,
        ),
        ContextMenuAction(
          icon: LucideIcons.copyPlus,
          label: "Duplicate",
          onPressed: widget.onDuplicate,
        ),
        ContextMenuAction(
          icon: snippet.pinned ? LucideIcons.pinOff : LucideIcons.pin,
          label: snippet.pinned ? "Unpin" : "Pin",
          onPressed: widget.onTogglePin,
        ),
        ContextMenuAction(
          icon: LucideIcons.trash2,
          label: "Delete",
          onPressed: widget.onDelete,
          destructive: true,
        ),
      ],
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    isSecret ? LucideIcons.keyRound : LucideIcons.terminal,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              snippet.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (snippet.pinned) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.pin,
                              size: 13,
                              color: scheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSecret ? "••••••••••" : snippet.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: isSecret ? null : AppTheme.mono,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Snippet options",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.ellipsis, size: 20),
                  onPressed: () => _menuKey.currentState?.open(),
                ),
                if (widget.reorderable)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ReorderableDragStartListener(
                      index: widget.index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          LucideIcons.gripVertical,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  const _ColumnHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$count",
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  final bool searching;
  const _EmptyColumn({required this.searching});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        searching ? "No matches" : "Nothing here yet",
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            "No snippets match your search",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

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
              "Save reusable secrets like tokens, or commands you run often, "
              "then drop them into any terminal with a tap.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: const Text("Add your first snippet"),
            ),
          ],
        ),
      ),
    );
  }
}
