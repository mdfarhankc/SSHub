import 'package:sshub/features/workflows/data/datasources/workflow_datasource.dart';
import 'package:sshub/features/workflows/data/models/workflow_model.dart';
import 'package:sshub/features/workflows/domain/entities/workflow.dart';
import 'package:sshub/features/workflows/domain/repositories/workflow_repository.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final WorkflowDatasource _localDatasource;
  WorkflowRepositoryImpl(this._localDatasource);

  // Writes are load-modify-save, so they are chained: two overlapping calls
  // would otherwise read the same list and the later save would lose an update.
  Future<void> _writes = Future.value();

  Future<void> _serialize(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then((_) {}, onError: (_) {});
    return next;
  }

  @override
  Future<List<Workflow>> getWorkflows() => _localDatasource.load();

  @override
  Future<void> addWorkflow(Workflow workflow) => _serialize(() async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save([
      ...workflows,
      WorkflowModel.fromEntity(workflow),
    ]);
  });

  @override
  Future<void> updateWorkflow(Workflow workflow) => _serialize(() async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save([
      for (final w in workflows)
        if (w.id == workflow.id) WorkflowModel.fromEntity(workflow) else w,
    ]);
  });

  @override
  Future<void> deleteWorkflow(String id) => _serialize(() async {
    final workflows = await _localDatasource.load();
    await _localDatasource.save(workflows.where((w) => w.id != id).toList());
  });

  @override
  Future<void> reorderWorkflows(List<Workflow> workflows) => _serialize(
    () => _localDatasource.save([
      for (final w in workflows) WorkflowModel.fromEntity(w),
    ]),
  );

  @override
  Future<void> clearAll() => _serialize(_localDatasource.clear);
}
