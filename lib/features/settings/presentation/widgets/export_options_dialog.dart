import 'package:flutter/material.dart';

class ExportOptions {
  final bool includeServers;
  final bool includeSettings;
  final bool includeSnippets;
  final String? passphrase;
  const ExportOptions({
    required this.includeServers,
    required this.includeSettings,
    required this.includeSnippets,
    this.passphrase,
  });
}

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({super.key});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _verify = TextEditingController();
  bool _servers = true;
  bool _settings = true;
  bool _snippets = true;
  bool _encrypt = false;
  bool _obscured = true;

  @override
  void dispose() {
    _pass.dispose();
    _verify.dispose();
    super.dispose();
  }

  void _submit() {
    if (_encrypt && !_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExportOptions(
        includeServers: _servers,
        includeSettings: _settings,
        includeSnippets: _snippets,
        passphrase: _encrypt ? _pass.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExport = _servers || _settings || _snippets;
    return AlertDialog(
      title: const Text("Export data"),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 480 ? double.maxFinite : 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Include servers"),
                subtitle: const Text("Servers and their passwords"),
                value: _servers,
                onChanged: (v) => setState(() => _servers = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Include snippets"),
                subtitle: const Text("Saved tokens and commands"),
                value: _snippets,
                onChanged: (v) => setState(() => _snippets = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Include settings"),
                value: _settings,
                onChanged: (v) => setState(() => _settings = v ?? false),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Encrypt data"),
                subtitle: Text(
                  _encrypt
                      ? "Protected with a passphrase"
                      : "Secrets will be stored in plain text",
                ),
                value: _encrypt,
                onChanged: (v) => setState(() => _encrypt = v),
              ),
              if (_encrypt) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pass,
                  obscureText: _obscured,
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
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _verify,
                  obscureText: _obscured,
                  decoration: const InputDecoration(
                    labelText: "Confirm passphrase",
                  ),
                  validator: (v) => v != _pass.text ? "Does not match" : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: canExport ? _submit : null,
          child: const Text("Export"),
        ),
      ],
    );
  }
}
