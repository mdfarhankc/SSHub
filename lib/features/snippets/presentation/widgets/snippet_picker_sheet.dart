import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/presentation/bloc/snippet_list_bloc.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';

// What to do with the chosen snippet: type it in, type and run it, or copy it.
enum SnippetUse { insert, run, copy }

class SnippetPickerSheet extends StatefulWidget {
  final void Function(Snippet snippet, SnippetUse use) onSelected;
  const SnippetPickerSheet({super.key, required this.onSelected});

  @override
  State<SnippetPickerSheet> createState() => _SnippetPickerSheetState();
}

class _SnippetPickerSheetState extends State<SnippetPickerSheet> {
  final _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Pinned snippets come first, then a label/command match on the query.
  List<Snippet> _visible(List<Snippet> all) {
    final q = _query.trim().toLowerCase();
    final matched = [
      for (final s in all)
        if (q.isEmpty ||
            s.label.toLowerCase().contains(q) ||
            (!s.isSecret && s.value.toLowerCase().contains(q)))
          s,
    ];
    return [
      ...matched.where((s) => s.pinned),
      ...matched.where((s) => !s.pinned),
    ];
  }

  void _use(Snippet snippet, SnippetUse use) {
    widget.onSelected(snippet, use);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: BlocBuilder<SnippetListBloc, SnippetListState>(
        builder: (context, state) {
          final visible = _visible(state.snippets);
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
              if (state.snippets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    // Enter drops in the top match, so it is a quick palette.
                    onSubmitted: (_) {
                      if (visible.isNotEmpty) {
                        _use(visible.first, SnippetUse.insert);
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Search snippets",
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const Divider(height: 1),
              if (state.snippets.isEmpty)
                const _EmptyPicker()
              else if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text("No snippets match your search"),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => _PickerRow(
                      snippet: visible[index],
                      onInsert: () => _use(visible[index], SnippetUse.insert),
                      onRun: () => _use(visible[index], SnippetUse.run),
                      onCopy: () => _use(visible[index], SnippetUse.copy),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final Snippet snippet;
  final VoidCallback onInsert;
  final VoidCallback onRun;
  final VoidCallback onCopy;
  const _PickerRow({
    required this.snippet,
    required this.onInsert,
    required this.onRun,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSecret = snippet.isSecret;
    return ListTile(
      leading: Icon(
        isSecret ? LucideIcons.keyRound : LucideIcons.terminal,
        color: scheme.primary,
      ),
      title: Row(
        children: [
          Flexible(child: Text(snippet.label, overflow: TextOverflow.ellipsis)),
          if (snippet.pinned) ...[
            const SizedBox(width: 6),
            Icon(LucideIcons.pin, size: 12, color: scheme.primary),
          ],
        ],
      ),
      subtitle: Text(
        isSecret ? "Hidden secret" : snippet.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: isSecret ? null : AppTheme.mono,
        ),
      ),
      // Tapping inserts; run and copy are explicit.
      onTap: onInsert,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSecret)
            IconButton(
              tooltip: "Run",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.play, size: 18),
              onPressed: onRun,
            ),
          IconButton(
            tooltip: "Copy",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(LucideIcons.zap, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text("No snippets yet", style: theme.textTheme.titleSmall),
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
    );
  }
}
