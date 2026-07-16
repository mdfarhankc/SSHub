import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';

class PassphraseDialog extends StatefulWidget {
  const PassphraseDialog({super.key});

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      icon: LucideIcons.lock,
      title: "Enter passphrase",
      subtitle: "This backup is encrypted",
      confirmLabel: "Unlock",
      onConfirm: _submit,
      body: Form(
        key: _formKey,
        child: DialogField(
          controller: _pass,
          name: "Passphrase",
          icon: LucideIcons.asterisk,
          obscureText: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
