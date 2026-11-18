import 'package:equatable/equatable.dart';

// A secret is hidden and reveal-gated; a command is plain text shown in full.
enum SnippetType { secret, command }

class Snippet extends Equatable {
  final String id;
  final String label;
  final String value;
  final SnippetType type;
  final bool pinned;
  // Command snippets only: selecting it sends and runs it, instead of just
  // typing it into the prompt.
  final bool autoRun;
  // null means the snippet is global; otherwise it belongs to this one server.
  final String? serverId;

  const Snippet({
    required this.id,
    required this.label,
    required this.value,
    this.type = SnippetType.secret,
    this.pinned = false,
    this.autoRun = false,
    this.serverId,
  });

  bool get isSecret => type == SnippetType.secret;
  bool get isGlobal => serverId == null;

  Snippet copyWith({
    String? label,
    String? value,
    SnippetType? type,
    bool? pinned,
    bool? autoRun,
  }) => Snippet(
    id: id,
    label: label ?? this.label,
    value: value ?? this.value,
    type: type ?? this.type,
    pinned: pinned ?? this.pinned,
    autoRun: autoRun ?? this.autoRun,
    serverId: serverId,
  );

  @override
  List<Object?> get props => [
    id,
    label,
    value,
    type,
    pinned,
    autoRun,
    serverId,
  ];
}
