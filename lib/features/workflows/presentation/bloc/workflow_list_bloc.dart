import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:sshub/features/workflows/domain/repositories/workflow_repository.dart';

part 'workflow_list_state.dart';
part 'workflow_list_event.dart';

class WorkflowListBloc extends Bloc<WorkflowListEvent, WorkflowListState> {
  final WorkflowRepository _repository;

  WorkflowListBloc(this._repository) : super(const WorkflowListState()) {
    on<WorkflowListLoaded>(_onLoaded);
    on<WorkflowAdded>(_onAdded);
    on<WorkflowUpdated>(_onUpdated);
    on<WorkflowDeleted>(_onDeleted);
    on<WorkflowsReordered>(_onReordered);
  }

  Future<void> _onLoaded(
    WorkflowListLoaded event,
    Emitter<WorkflowListState> emit,
  ) async {
    emit(state.copyWith(status: WorkflowListStatus.loading));
    try {
      final workflows = await _repository.getWorkflows();
      emit(
        state.copyWith(
          status: WorkflowListStatus.success,
          workflows: workflows,
        ),
      );
    } catch (e) {
      appLog("Load workflows failed", e);
      emit(state.copyWith(status: WorkflowListStatus.failure));
    }
  }

  Future<void> _onAdded(
    WorkflowAdded event,
    Emitter<WorkflowListState> emit,
  ) async {
    try {
      await _repository.addWorkflow(event.workflow);
      emit(state.copyWith(workflows: [...state.workflows, event.workflow]));
    } catch (e) {
      appLog("Add workflow failed", e);
      emit(state.copyWith(errorMessage: "Could not add workflow"));
    }
  }

  Future<void> _onUpdated(
    WorkflowUpdated event,
    Emitter<WorkflowListState> emit,
  ) async {
    try {
      await _repository.updateWorkflow(event.workflow);
      emit(
        state.copyWith(
          workflows: [
            for (final w in state.workflows)
              if (w.id == event.workflow.id) event.workflow else w,
          ],
        ),
      );
    } catch (e) {
      appLog("Update workflow failed", e);
      emit(state.copyWith(errorMessage: "Could not update workflow"));
    }
  }

  Future<void> _onDeleted(
    WorkflowDeleted event,
    Emitter<WorkflowListState> emit,
  ) async {
    try {
      await _repository.deleteWorkflow(event.id);
      emit(
        state.copyWith(
          workflows: state.workflows.where((w) => w.id != event.id).toList(),
        ),
      );
    } catch (e) {
      appLog("Delete workflow failed", e);
      emit(state.copyWith(errorMessage: "Could not delete workflow"));
    }
  }

  Future<void> _onReordered(
    WorkflowsReordered event,
    Emitter<WorkflowListState> emit,
  ) async {
    emit(state.copyWith(workflows: event.workflows));
    try {
      await _repository.reorderWorkflows(event.workflows);
    } catch (e) {
      appLog("Reorder workflows failed", e);
      emit(state.copyWith(errorMessage: "Could not save the new order"));
    }
  }
}
