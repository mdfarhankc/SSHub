import 'package:flutter/material.dart';

// Asks for a single file or folder name. Returns null when cancelled.
class NamePromptDialog extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String? initialValue;

  const NamePromptDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialValue,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    String? initialValue,
  }) => showDialog<String>(
    context: context,
    builder: (_) => NamePromptDialog(
      title: title,
      actionLabel: actionLabel,
      initialValue: initialValue,
    ),
  );

  @override
  State<NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<NamePromptDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    // A name with a slash would silently move the entry somewhere else.
    final invalid =
        name.isEmpty || name.contains('/') || name == '.' || name == '..';
    if (invalid) {
      setState(() => _error = "Enter a name without slashes");
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: "Name", errorText: _error),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}
