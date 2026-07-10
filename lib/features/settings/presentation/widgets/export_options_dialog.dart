import 'package:flutter/material.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/core/widgets/section_header.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';

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
  bool _encrypt = true;

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
    return AppFormSheet(
      icon: Icons.upload_rounded,
      title: "Export data",
      subtitle: "Choose what to include in your backup",
      confirmLabel: "Export",
      onConfirm: canExport ? _submit : null,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.checklist_rounded,
              title: "Include",
            ),
            const SizedBox(height: 12),
            _Group(
              children: [
                _toggle(
                  icon: Icons.dns_outlined,
                  title: "Servers",
                  subtitle: "Servers and their passwords",
                  value: _servers,
                  onChanged: (v) => setState(() => _servers = v),
                ),
                _toggle(
                  icon: Icons.bolt_outlined,
                  title: "Snippets",
                  subtitle: "Saved tokens and commands",
                  value: _snippets,
                  onChanged: (v) => setState(() => _snippets = v),
                ),
                _toggle(
                  icon: Icons.tune_rounded,
                  title: "Settings",
                  subtitle: "App preferences",
                  value: _settings,
                  onChanged: (v) => setState(() => _settings = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(icon: Icons.lock_outline, title: "Encryption"),
            const SizedBox(height: 12),
            _Group(
              children: [
                _toggle(
                  icon: Icons.enhanced_encryption_outlined,
                  title: "Encrypt backup",
                  subtitle: _encrypt
                      ? "Protected with a passphrase"
                      : "Secrets will be stored in plain text",
                  value: _encrypt,
                  onChanged: (v) => setState(() => _encrypt = v),
                ),
                if (_encrypt)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      children: [
                        DialogField(
                          controller: _pass,
                          name: "Passphrase",
                          icon: Icons.password_outlined,
                          hint: "At least 12 characters",
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (v.length < 12) {
                              return "Use at least 12 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DialogField(
                          controller: _verify,
                          name: "Confirm passphrase",
                          icon: Icons.password_outlined,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) =>
                              v != _pass.text ? "Does not match" : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}
