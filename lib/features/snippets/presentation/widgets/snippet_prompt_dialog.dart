import 'package:flutter/material.dart';

import 'package:sshub/features/snippets/domain/snippet_placeholders.dart';

// Collects the values a command's {{Label}} tokens ask for. A prompt with
// suggested options shows them as chips the user can pick or type past. Returns
// the key-to-value map, or null if cancelled.
class SnippetPromptDialog extends StatefulWidget {
  final String title;
  final List<SnippetPrompt> prompts;
  const SnippetPromptDialog({
    super.key,
    required this.title,
    required this.prompts,
  });

  static Future<Map<String, String>?> show(
    BuildContext context,
    String title,
    List<SnippetPrompt> prompts,
  ) => showDialog<Map<String, String>>(
    context: context,
    builder: (_) => SnippetPromptDialog(title: title, prompts: prompts),
  );

  @override
  State<SnippetPromptDialog> createState() => _SnippetPromptDialogState();
}

class _SnippetPromptDialogState extends State<SnippetPromptDialog> {
  // Seeded with the first option so a pick-list prompt has a sensible default.
  late final Map<String, TextEditingController> _controllers = {
    for (final prompt in widget.prompts)
      prompt.key: TextEditingController(
        text: prompt.options.isNotEmpty ? prompt.options.first : '',
      ),
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.prompts.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _PromptField(
                prompt: widget.prompts[i],
                controller: _controllers[widget.prompts[i].key]!,
                autofocus: i == 0,
                isLast: i == widget.prompts.length - 1,
                onSubmit: _submit,
              ),
            ],
          ],
        ),
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

class _PromptField extends StatefulWidget {
  final SnippetPrompt prompt;
  final TextEditingController controller;
  final bool autofocus;
  final bool isLast;
  final VoidCallback onSubmit;
  const _PromptField({
    required this.prompt,
    required this.controller,
    required this.autofocus,
    required this.isLast,
    required this.onSubmit,
  });

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  @override
  Widget build(BuildContext context) {
    final options = widget.prompt.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option),
                    selected: widget.controller.text == option,
                    onSelected: (_) => setState(() {
                      widget.controller.text = option;
                    }),
                  ),
              ],
            ),
          ),
        TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          decoration: InputDecoration(
            labelText: widget.prompt.label.isEmpty
                ? "Select an option"
                : widget.prompt.label,
          ),
          // Keeps the selected chip in step with what is typed.
          onChanged: options.isEmpty ? null : (_) => setState(() {}),
          onSubmitted: (_) {
            if (widget.isLast) widget.onSubmit();
          },
        ),
      ],
    );
  }
}
