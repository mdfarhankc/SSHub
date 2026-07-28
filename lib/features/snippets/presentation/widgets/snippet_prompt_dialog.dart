import 'package:flutter/material.dart';

// Collects the values a command snippet's {{prompt:Label}} tokens ask for.
// Returns the label-to-value map, or null if cancelled.
class SnippetPromptDialog extends StatefulWidget {
  final String title;
  final List<String> prompts;
  const SnippetPromptDialog({
    super.key,
    required this.title,
    required this.prompts,
  });

  static Future<Map<String, String>?> show(
    BuildContext context,
    String title,
    List<String> prompts,
  ) => showDialog<Map<String, String>>(
    context: context,
    builder: (_) => SnippetPromptDialog(title: title, prompts: prompts),
  );

  @override
  State<SnippetPromptDialog> createState() => _SnippetPromptDialogState();
}

class _SnippetPromptDialogState extends State<SnippetPromptDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final prompt in widget.prompts) prompt: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.prompts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            TextField(
              controller: _controllers[widget.prompts[i]],
              autofocus: i == 0,
              textInputAction: i == widget.prompts.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(labelText: widget.prompts[i]),
              onSubmitted: (_) {
                if (i == widget.prompts.length - 1) _submit();
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(onPressed: _submit, child: const Text("Use")),
      ],
    );
  }
}
