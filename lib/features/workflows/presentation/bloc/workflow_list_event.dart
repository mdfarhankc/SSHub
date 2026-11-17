part of 'workflow_list_bloc.dart';

sealed class WorkflowListEvent {}

final class WorkflowListLoaded extends WorkflowListEvent {}

final class WorkflowAdded extends WorkflowListEvent {
  final Workflow workflow;
  WorkflowAdded(this.workflow);
}

final class WorkflowUpdated extends WorkflowListEvent {
  final Workflow workflow;
  WorkflowUpdated(this.workflow);
}

final class WorkflowDeleted extends WorkflowListEvent {
  final String id;
  WorkflowDeleted(this.id);
}

// Drops every workflow tied to a server that was deleted.
final class WorkflowsForServerRemoved extends WorkflowListEvent {
  final String serverId;
  WorkflowsForServerRemoved(this.serverId);
}

final class WorkflowsReordered extends WorkflowListEvent {
  final List<Workflow> workflows;
  WorkflowsReordered(this.workflows);
}
