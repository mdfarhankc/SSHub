import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/context_menu_area.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:sshub/features/workflows/presentation/bloc/workflow_list_bloc.dart';
import 'package:sshub/features/workflows/presentation/widgets/workflow_dialog.dart';
import 'package:uuid/uuid.dart';

class WorkflowsPage extends StatelessWidget {
  const WorkflowsPage({super.key});

  static const route = "/workflows";

  Future<void> _add(BuildContext context) async {
    final result = await WorkflowDialog.show(context);
    if (result != null && context.mounted) {
      context.read<WorkflowListBloc>().add(WorkflowAdded(result));
    }
  }

  Future<void> _edit(BuildContext context, Workflow workflow) async {
    final result = await WorkflowDialog.show(context, workflow: workflow);
    if (result != null && context.mounted) {
      context.read<WorkflowListBloc>().add(WorkflowUpdated(result));
    }
  }

  void _duplicate(BuildContext context, Workflow workflow) {
    context.read<WorkflowListBloc>().add(
      WorkflowAdded(
        Workflow(
          id: const Uuid().v7(),
          label: "${workflow.label} copy",
          steps: workflow.steps,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Workflow workflow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete workflow?"),
        content: Text("\"${workflow.label}\" will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<WorkflowListBloc>().add(WorkflowDeleted(workflow.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workflows")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text("New Workflow"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: BlocConsumer<WorkflowListBloc, WorkflowListState>(
            listenWhen: (_, current) => current.errorMessage != null,
            listener: (context, state) =>
                showAppSnackBar(context, state.errorMessage!, success: false),
            builder: (context, state) {
              if (state.status == WorkflowListStatus.failure) {
                return const _LoadFailed();
              }
              if (state.workflows.isEmpty) {
                return _EmptyState(onAdd: () => _add(context));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: state.workflows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final workflow = state.workflows[index];
                  return _WorkflowTile(
                    workflow: workflow,
                    onEdit: () => _edit(context, workflow),
                    onDuplicate: () => _duplicate(context, workflow),
                    onDelete: () => _delete(context, workflow),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WorkflowTile extends StatefulWidget {
  final Workflow workflow;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  const _WorkflowTile({
    required this.workflow,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<_WorkflowTile> createState() => _WorkflowTileState();
}

class _WorkflowTileState extends State<_WorkflowTile> {
  final _menuKey = GlobalKey<ContextMenuAreaState>();

  Workflow get workflow => widget.workflow;

  String get _subtitle {
    final count = workflow.steps.length;
    final steps = "$count ${count == 1 ? 'step' : 'steps'}";
    final first = workflow.steps.isEmpty ? '' : workflow.steps.first.send;
    return first.isEmpty ? steps : "$steps  ·  $first";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ContextMenuArea(
      key: _menuKey,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      actions: [
        ContextMenuAction(
          icon: LucideIcons.pencil,
          label: "Edit",
          onPressed: widget.onEdit,
        ),
        ContextMenuAction(
          icon: LucideIcons.copyPlus,
          label: "Duplicate",
          onPressed: widget.onDuplicate,
        ),
        ContextMenuAction(
          icon: LucideIcons.trash2,
          label: "Delete",
          onPressed: widget.onDelete,
          destructive: true,
        ),
      ],
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    LucideIcons.workflow,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              workflow.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (workflow.hasSecret) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.lock,
                              size: 13,
                              color: scheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: AppTheme.mono,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Workflow options",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.ellipsis, size: 20),
                  onPressed: () => _menuKey.currentState?.open(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 56,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text("Could not load workflows", style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                context.read<WorkflowListBloc>().add(WorkflowListLoaded()),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.workflow,
                size: 64,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No workflows yet",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Chain a command with the replies it needs, like a git pull that "
              "answers the username and password prompts, then run it in one tap.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: const Text("Create your first workflow"),
            ),
          ],
        ),
      ),
    );
  }
}
