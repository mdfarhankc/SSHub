import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/auth/reveal_guard.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class SnippetDialog extends StatefulWidget {
  final Snippet? snippet;
  const SnippetDialog({super.key, this.snippet});

  static Future<Snippet?> show(BuildContext context, {Snippet? snippet}) =>
      showBlurredBottomSheet<Snippet>(
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
  late SnippetType _type;

  bool get _isEditing => widget.snippet != null;
  bool get _isSecret => _type == SnippetType.secret;

  @override
  void initState() {
    super.initState();
    _type = widget.snippet?.type ?? SnippetType.secret;
    // Commands are not hidden, so an existing one shows its value right away.
    if (_isEditing && !widget.snippet!.isSecret) {
      _value.text = widget.snippet!.value;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // A secret keeps its stored value when the field is left blank on edit; a
    // command always uses what is shown.
    final keepSecret = _isSecret && _isEditing && _value.text.isEmpty;
    final value = keepSecret ? (widget.snippet?.value ?? '') : _value.text;
    Navigator.pop(
      context,
      Snippet(
        id: widget.snippet?.id ?? const Uuid().v7(),
        label: _label.text.trim(),
        value: value,
        type: _type,
        pinned: widget.snippet?.pinned ?? false,
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

  String get _valueHint {
    if (_isSecret) {
      return _isEditing ? "Leave blank to keep current" : "Token or password";
    }
    return "e.g. sudo systemctl restart {{prompt:service}}";
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    icon: _isEditing ? LucideIcons.notebookPen : LucideIcons.zap,
    title: _isEditing ? "Edit snippet" : "New snippet",
    subtitle: _isEditing
        ? "Update your saved snippet"
        : "Save a reusable secret or command",
    confirmLabel: _isEditing ? "Save" : "Add",
    onConfirm: _submit,
    body: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<SnippetType>(
            segments: const [
              ButtonSegment(
                value: SnippetType.secret,
                label: Text("Secret"),
                icon: Icon(LucideIcons.keyRound, size: 16),
              ),
              ButtonSegment(
                value: SnippetType.command,
                label: Text("Command"),
                icon: Icon(LucideIcons.terminal, size: 16),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
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
            icon: _isSecret ? LucideIcons.keyRound : LucideIcons.terminal,
            obscureText: _isSecret,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            required: !_isSecret || !_isEditing,
            hint: _valueHint,
            onReveal: _isSecret && _isEditing ? _revealValue : null,
          ),
          const SizedBox(height: 10),
          _PlaceholderHint(visible: !_isSecret),
        ],
      ),
    ),
  );
}

// Explains the tokens a command can carry. Hidden for secrets, which are pasted
// verbatim.
class _PlaceholderHint extends StatelessWidget {
  final bool visible;
  const _PlaceholderHint({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "Insert {{host}}, {{user}} or {{port}} for the current session, or "
            "{{prompt:Label}} to ask when used.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
