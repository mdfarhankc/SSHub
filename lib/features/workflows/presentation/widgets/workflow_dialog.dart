import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/blurred_bottom_sheet.dart';
import 'package:sshub/core/widgets/section_header.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:uuid/uuid.dart';

class WorkflowDialog extends StatefulWidget {
  final Workflow? workflow;
  const WorkflowDialog({super.key, this.workflow});

  static Future<Workflow?> show(BuildContext context, {Workflow? workflow}) =>
      showBlurredBottomSheet<Workflow>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => WorkflowDialog(workflow: workflow),
      );

  @override
  State<WorkflowDialog> createState() => _WorkflowDialogState();
}

class _StepFields {
  final TextEditingController title;
  final TextEditingController expect;
  final TextEditingController send;
  bool secret;
  _StepFields({
    String title = '',
    String expect = '',
    String send = '',
    this.secret = false,
  }) : title = TextEditingController(text: title),
       expect = TextEditingController(text: expect),
       send = TextEditingController(text: send);
  void dispose() {
    title.dispose();
    expect.dispose();
    send.dispose();
  }
}

class _WorkflowDialogState extends State<WorkflowDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.workflow?.label ?? "");
  late final List<_StepFields> _steps;

  bool get _isEditing => widget.workflow != null;

  @override
  void initState() {
    super.initState();
    final steps = widget.workflow?.steps ?? const <WorkflowStep>[];
    _steps = steps.isEmpty
        ? [_StepFields()]
        : [
            for (final s in steps)
              _StepFields(
                title: s.title,
                expect: s.expect,
                send: s.send,
                secret: s.secret,
              ),
          ];
  }

  @override
  void dispose() {
    _label.dispose();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStep() => setState(() => _steps.add(_StepFields()));

  void _removeStep(int index) =>
      setState(() => _steps.removeAt(index).dispose());

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final steps = [
      for (final s in _steps)
        if (s.send.text.trim().isNotEmpty)
          WorkflowStep(
            title: s.title.text.trim(),
            expect: s.expect.text.trim(),
            send: s.send.text,
            secret: s.secret,
          ),
    ];
    if (steps.isEmpty) {
      showAppSnackBar(context, "Add at least one step to send", success: false);
      return;
    }
    Navigator.pop(
      context,
      Workflow(
        id: widget.workflow?.id ?? const Uuid().v7(),
        label: _label.text.trim(),
        steps: steps,
        pinned: widget.workflow?.pinned ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    icon: _isEditing ? LucideIcons.notebookPen : LucideIcons.workflow,
    title: _isEditing ? "Edit workflow" : "New workflow",
    subtitle: _isEditing
        ? "Update your saved workflow"
        : "Chain commands and prompt replies into one run",
    confirmLabel: _isEditing ? "Save" : "Add",
    onConfirm: _submit,
    body: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DialogField(
            controller: _label,
            name: "Label",
            hint: "e.g. Git pull",
            icon: LucideIcons.tag,
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 20),
          const SectionHeader(icon: LucideIcons.listOrdered, title: "Steps"),
          const SizedBox(height: 12),
          for (var i = 0; i < _steps.length; i++) ...[
            _StepCard(
              index: i,
              fields: _steps[i],
              canRemove: _steps.length > 1,
              onRemove: () => _removeStep(i),
              onSecretChanged: (v) => setState(() => _steps[i].secret = v),
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text("Add step"),
            ),
          ),
          const SizedBox(height: 4),
          const _PlaceholderHint(),
        ],
      ),
    ),
  );
}

class _StepCard extends StatelessWidget {
  final int index;
  final _StepFields fields;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<bool> onSecretChanged;
  const _StepCard({
    required this.index,
    required this.fields,
    required this.canRemove,
    required this.onRemove,
    required this.onSecretChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: fields.title,
                  builder: (context, value, _) {
                    final name = value.text.trim();
                    return Text(
                      name.isEmpty
                          ? "Step ${index + 1}"
                          : "Step ${index + 1}  ·  $name",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: "Remove step",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: onRemove,
                ),
            ],
          ),
          TextField(
            controller: fields.title,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              isDense: true,
              labelText: "Name (optional)",
              hintText: "e.g. Log in as the project user",
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: fields.expect,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              isDense: true,
              labelText: "Wait for this text (optional)",
              hintText:
                  "Only to reply to a prompt, e.g. Password. Empty = send now",
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: fields.send,
            style: theme.textTheme.bodyMedium,
            obscureText: fields.secret,
            decoration: const InputDecoration(
              isDense: true,
              labelText: "Send",
              hintText: "e.g. git pull  ·  {{user}}  ·  {{prompt:Token}}",
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Switch(value: fields.secret, onChanged: onSecretChanged),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Secret — hide the value and ask to unlock before running",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderHint extends StatelessWidget {
  const _PlaceholderHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "A step sends its text, then Enter. Use {{host}}, {{user}}, {{port}} "
            "for the current server, or {{prompt:Label}} to ask when it runs.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
