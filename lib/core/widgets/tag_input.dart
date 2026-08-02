import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Normalises a raw tag so "Prod", " prod " and "PROD" collapse to one value.
// Returns null when nothing usable is left.
String? normalizeTag(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.isEmpty) return null;
  return t.length > 24 ? t.substring(0, 24) : t;
}

// A chip editor for a server's tags: shows the current tags, a field to add
// more (Enter or comma commits), and one-tap chips for tags used elsewhere.
class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;

  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Splits on commas so a pasted "a, b, c" adds three, deduping as it goes.
  void _commit(String raw) {
    final next = [...widget.tags];
    for (final part in raw.split(',')) {
      final tag = normalizeTag(part);
      if (tag != null && !next.contains(tag)) next.add(tag);
    }
    _controller.clear();
    if (next.length != widget.tags.length) widget.onChanged(next);
  }

  void _add(String tag) {
    if (!widget.tags.contains(tag)) widget.onChanged([...widget.tags, tag]);
  }

  void _remove(String tag) =>
      widget.onChanged(widget.tags.where((t) => t != tag).toList());

  @override
  Widget build(BuildContext context) {
    // Only suggest tags used on other servers that are not already added here.
    final available = widget.suggestions
        .where((t) => !widget.tags.contains(t))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.tags)
                Chip(
                  label: Text(tag),
                  onDeleted: () => _remove(tag),
                  deleteIcon: const Icon(LucideIcons.x, size: 14),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            isDense: true,
            hintText: "Add a tag",
            prefixIcon: const Icon(LucideIcons.tag, size: 18),
            suffixIcon: IconButton(
              tooltip: "Add",
              icon: const Icon(LucideIcons.plus, size: 18),
              onPressed: () => _commit(_controller.text),
            ),
          ),
          onChanged: (v) {
            if (v.contains(',')) _commit(v);
          },
          onSubmitted: _commit,
        ),
        if (available.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in available.take(12))
                ActionChip(
                  label: Text(tag),
                  avatar: const Icon(LucideIcons.plus, size: 14),
                  onPressed: () => _add(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
