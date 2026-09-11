import 'package:equatable/equatable.dart';

// One step of a workflow. When [expect] is empty the step sends as soon as the
// previous one is done; otherwise it waits until the terminal output contains
// [expect] before sending. [secret] hides the value in the editor and gates the
// run behind app lock, for things like a password.
class WorkflowStep extends Equatable {
  final String title;
  final String expect;
  final String send;
  final bool secret;

  const WorkflowStep({
    this.title = '',
    this.expect = '',
    required this.send,
    this.secret = false,
  });

  bool get waits => expect.trim().isNotEmpty;

  WorkflowStep copyWith({
    String? title,
    String? expect,
    String? send,
    bool? secret,
  }) => WorkflowStep(
    title: title ?? this.title,
    expect: expect ?? this.expect,
    send: send ?? this.send,
    secret: secret ?? this.secret,
  );

  @override
  List<Object?> get props => [title, expect, send, secret];
}

class Workflow extends Equatable {
  final String id;
  final String label;
  final List<WorkflowStep> steps;
  final bool pinned;

  const Workflow({
    required this.id,
    required this.label,
    this.steps = const [],
    this.pinned = false,
  });

  bool get hasSecret => steps.any((s) => s.secret);

  Workflow copyWith({String? label, List<WorkflowStep>? steps, bool? pinned}) =>
      Workflow(
        id: id,
        label: label ?? this.label,
        steps: steps ?? this.steps,
        pinned: pinned ?? this.pinned,
      );

  @override
  List<Object?> get props => [id, label, steps, pinned];
}
