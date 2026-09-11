import 'package:sshub/features/workflows/domain/entities/workflow.dart';

class WorkflowModel extends Workflow {
  const WorkflowModel({
    required super.id,
    required super.label,
    super.steps,
    super.pinned,
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) => WorkflowModel(
    id: json['id'] as String,
    label: json['label'] as String,
    steps: [
      for (final s in (json['steps'] as List? ?? const []))
        _stepFrom(s as Map<String, dynamic>),
    ],
    pinned: json['pinned'] as bool? ?? false,
  );

  static WorkflowStep _stepFrom(Map<String, dynamic> json) => WorkflowStep(
    title: json['title'] as String? ?? '',
    expect: json['expect'] as String? ?? '',
    send: json['send'] as String? ?? '',
    secret: json['secret'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'steps': [
      for (final s in steps)
        {
          'title': s.title,
          'expect': s.expect,
          'send': s.send,
          'secret': s.secret,
        },
    ],
    'pinned': pinned,
  };

  factory WorkflowModel.fromEntity(Workflow e) =>
      WorkflowModel(id: e.id, label: e.label, steps: e.steps, pinned: e.pinned);
}
