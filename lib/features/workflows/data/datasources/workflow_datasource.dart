import 'package:sshub/features/workflows/data/models/workflow_model.dart';

abstract interface class WorkflowDatasource {
  Future<List<WorkflowModel>> load();
  Future<void> save(List<WorkflowModel> workflows);
  Future<void> clear();
}
