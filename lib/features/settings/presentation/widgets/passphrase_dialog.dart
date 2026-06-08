import 'package:flutter/material.dart';

class PassphraseDialog extends StatefulWidget {
  const PassphraseDialog({super.key});

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _pass = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pass.text.isNotEmpty) Navigator.pop(context, _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter passphrase"),
      content: TextField(
        controller: _pass,
        autofocus: true,
        obscureText: _obscured,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: "Passphrase",
          suffixIcon: IconButton(
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(onPressed: _submit, child: const Text("Unlock")),
      ],
    );
  }
}
