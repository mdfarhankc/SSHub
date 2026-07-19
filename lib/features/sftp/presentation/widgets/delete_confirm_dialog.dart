import 'package:flutter/material.dart';

import 'package:sshub/features/sftp/domain/entities/remote_file.dart';

// Folder deletes take everything inside, so the name must be typed back.
class DeleteConfirmDialog extends StatefulWidget {
  final RemoteFile file;

  const DeleteConfirmDialog({super.key, required this.file});

  static Future<bool> show(BuildContext context, RemoteFile file) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(file: file),
    );
    return result ?? false;
  }

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  final _controller = TextEditingController();

  bool get _needsTyping => widget.file.isDirectory;

  bool get _canDelete =>
      !_needsTyping || _controller.text.trim() == widget.file.name;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_canDelete) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.file.name;

    return AlertDialog(
      scrollable: true,
      title: Text(_needsTyping ? "Delete folder?" : "Delete file?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _needsTyping
                ? '"$name" and everything inside it will be deleted from the server. This cannot be undone.'
                : '"$name" will be deleted from the server. This cannot be undone.',
          ),
          if (_needsTyping) ...[
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "Type "),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " to confirm"),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(isDense: true),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _canDelete ? _confirm : null,
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
