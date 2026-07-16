import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/auth/reveal_guard.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class SnippetDialog extends StatefulWidget {
  final Snippet? snippet;
  const SnippetDialog({super.key, this.snippet});

  static Future<Snippet?> show(BuildContext context, {Snippet? snippet}) =>
      showModalBottomSheet<Snippet>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
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
    // Secrets pass through untouched; a blank field on edit keeps the stored value.
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
    final locked = context
        .read<SettingsCubit>()
        .state
        .settings
        .lockSnippetReveal;
    final ok = await context.confirmReveal(
      locked: locked,
      reason: "Reveal saved snippet value",
    );
    final value = widget.snippet?.value ?? '';
    if (!ok || !mounted || value.isEmpty) return false;
    _value.text = value;
    return true;
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    icon: _isEditing ? LucideIcons.notebookPen : LucideIcons.zap,
    title: _isEditing ? "Edit snippet" : "New snippet",
    subtitle: _isEditing
        ? "Update your saved value"
        : "Save a reusable token or command",
    confirmLabel: _isEditing ? "Save" : "Add",
    onConfirm: _submit,
    body: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogField(
            controller: _label,
            name: "Label",
            hint: "e.g. GitLab token",
            icon: LucideIcons.tag,
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 12),
          DialogField(
            controller: _value,
            name: "Value",
            icon: LucideIcons.keyRound,
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
  );
}
