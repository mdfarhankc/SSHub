part of 'workflow_list_bloc.dart';

enum WorkflowListStatus { initial, loading, success, failure }

class WorkflowListState extends Equatable {
  final WorkflowListStatus status;
  final List<Workflow> workflows;
  final String? errorMessage;
  const WorkflowListState({
    this.status = WorkflowListStatus.initial,
    this.workflows = const [],
    this.errorMessage,
  });

  WorkflowListState copyWith({
    WorkflowListStatus? status,
    List<Workflow>? workflows,
    String? errorMessage,
  }) => WorkflowListState(
    status: status ?? this.status,
    workflows: workflows ?? this.workflows,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, workflows, errorMessage];
}
