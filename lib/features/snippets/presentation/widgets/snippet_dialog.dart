import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class SnippetDialog extends StatefulWidget {
  final Snippet? snippet;
  const SnippetDialog({super.key, this.snippet});

  static Future<Snippet?> show(BuildContext context, {Snippet? snippet}) =>
      showDialog<Snippet>(
        context: context,
        builder: (_) => SnippetDialog(snippet: snippet),
      );

  @override
  State<SnippetDialog> createState() => _SnippetDialogState();
}

class _SnippetDialogState extends State<SnippetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.snippet?.label ?? "");
  final _value = TextEditingController();

  bool get _isEditing => widget.snippet != null;

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Secrets pass through untouched: never trim.
    // When editing with the field left blank, keep the existing value.
    final value = _isEditing && _value.text.isEmpty
        ? (widget.snippet?.value ?? '')
        : _value.text;
    Navigator.pop(
      context,
      Snippet(
        id: widget.snippet?.id ?? const Uuid().v7(),
        label: _label.text.trim(),
        value: value,
      ),
    );
  }

  Future<bool> _revealValue() async {
    final auth = context.read<LocalAuthService>();
    final lock = context.read<SettingsCubit>().state.settings.lockSnippetReveal;
    if (lock) {
      final ok = await auth.authenticate("Reveal saved snippet value");
      if (!ok) return false;
    }
    final value = widget.snippet?.value ?? '';
    if (!mounted || value.isEmpty) return false;
    _value.text = value;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Edit snippet" : "New snippet"),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 480 ? double.maxFinite : 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogField(
                controller: _label,
                name: "Label",
                hint: "e.g. GitLab token",
                icon: Icons.label_important_outlined,
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 12),
              DialogField(
                controller: _value,
                name: "Value",
                icon: Icons.vpn_key_outlined,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                required: !_isEditing,
                hint: _isEditing
                    ? "Leave blank to keep current"
                    : "Token, password, or command",
                onReveal: _isEditing ? _revealValue : null,
              ),
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
          onPressed: _submit,
          child: Text(_isEditing ? "Save" : "Add"),
        ),
      ],
    );
  }
}
