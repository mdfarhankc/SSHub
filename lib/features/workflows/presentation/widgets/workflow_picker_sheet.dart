import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:sshub/features/workflows/presentation/bloc/workflow_list_bloc.dart';
import 'package:sshub/features/workflows/presentation/pages/workflows_page.dart';

class WorkflowPickerSheet extends StatelessWidget {
  final void Function(Workflow workflow) onSelected;
  const WorkflowPickerSheet({super.key, required this.onSelected});

  void _run(BuildContext context, Workflow workflow) {
    // Close the sheet before the callback, which may push its own dialog.
    Navigator.pop(context);
    onSelected(workflow);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: BlocBuilder<WorkflowListBloc, WorkflowListState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.workflow, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      "Workflows",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pushNamed(WorkflowsPage.route);
                      },
                      icon: const Icon(LucideIcons.settings2, size: 18),
                      label: const Text("Manage"),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (state.workflows.isEmpty)
                const _EmptyPicker()
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.workflows.length,
                    itemBuilder: (context, index) {
                      final workflow = state.workflows[index];
                      final count = workflow.steps.length;
                      return ListTile(
                        leading: Icon(
                          LucideIcons.workflow,
                          color: scheme.primary,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                workflow.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (workflow.hasSecret) ...[
                              const SizedBox(width: 6),
                              Icon(
                                LucideIcons.lock,
                                size: 12,
                                color: scheme.primary,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          "$count ${count == 1 ? 'step' : 'steps'}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(LucideIcons.play, size: 18),
                        onTap: () => _run(context, workflow),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(LucideIcons.workflow, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text("No workflows yet", style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            "Create one from Manage to run a command and its prompt replies "
            "in a single tap.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
