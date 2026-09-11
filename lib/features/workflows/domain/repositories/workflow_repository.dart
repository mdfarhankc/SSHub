import 'package:sshub/features/workflows/domain/entities/workflow.dart';

abstract interface class WorkflowRepository {
  Future<List<Workflow>> getWorkflows();
  Future<void> addWorkflow(Workflow workflow);
  Future<void> updateWorkflow(Workflow workflow);
  Future<void> deleteWorkflow(String id);
  // Persists the given order verbatim.
  Future<void> reorderWorkflows(List<Workflow> workflows);
  Future<void> clearAll();
}
