import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

// Filters the current folder's listing by name as you type. Escape or the close
// button ends the search.
class SftpSearchField extends StatefulWidget {
  final SftpCubit cubit;
  final SftpState state;
  const SftpSearchField({super.key, required this.cubit, required this.state});

  @override
  State<SftpSearchField> createState() => _SftpSearchFieldState();
}

class _SftpSearchFieldState extends State<SftpSearchField> {
  late final _controller = TextEditingController(text: widget.state.searchQuery);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasQuery = widget.state.searchQuery.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape):
              widget.cubit.toggleSearch,
        },
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "Search this folder",
                ),
                onChanged: widget.cubit.setSearch,
              ),
            ),
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "${widget.state.visibleEntries.length}",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            IconButton(
              tooltip: "Close search",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: widget.cubit.toggleSearch,
            ),
          ],
        ),
      ),
    );
  }
}
