import 'package:sshub/features/workflows/data/datasources/workflow_datasource.dart';
import 'package:sshub/features/workflows/data/models/workflow_model.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:sshub/features/workflows/domain/repositories/workflow_repository.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final WorkflowDatasource _localDatasource;
  const WorkflowRepositoryImpl(this._localDatasource);

  @override
  Future<List<Workflow>> getWorkflows() => _localDatasource.load();

  @override
  Future<void> addWorkflow(Workflow workflow) async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save([
      ...workflows,
      WorkflowModel.fromEntity(workflow),
    ]);
  }

  @override
  Future<void> updateWorkflow(Workflow workflow) async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save([
      for (final w in workflows)
        if (w.id == workflow.id) WorkflowModel.fromEntity(workflow) else w,
    ]);
  }

  @override
  Future<void> deleteWorkflow(String id) async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save(workflows.where((w) => w.id != id).toList());
  }

  @override
  Future<void> reorderWorkflows(List<Workflow> workflows) => _localDatasource
      .save([for (final w in workflows) WorkflowModel.fromEntity(w)]);

  @override
  Future<void> clearAll() => _localDatasource.clear();
}
