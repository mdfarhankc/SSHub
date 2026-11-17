import 'package:equatable/equatable.dart';

// A secret is hidden and reveal-gated; a command is plain text shown in full.
enum SnippetType { secret, command }

class Snippet extends Equatable {
  final String id;
  final String label;
  final String value;
  final SnippetType type;
  final bool pinned;
  // null means the snippet is global; otherwise it belongs to this one server.
  final String? serverId;

  const Snippet({
    required this.id,
    required this.label,
    required this.value,
    this.type = SnippetType.secret,
    this.pinned = false,
    this.serverId,
  });

  bool get isSecret => type == SnippetType.secret;
  bool get isGlobal => serverId == null;

  Snippet copyWith({
    String? label,
    String? value,
    SnippetType? type,
    bool? pinned,
  }) => Snippet(
    id: id,
    label: label ?? this.label,
    value: value ?? this.value,
    type: type ?? this.type,
    pinned: pinned ?? this.pinned,
    serverId: serverId,
  );

  @override
  List<Object?> get props => [id, label, value, type, pinned, serverId];
}
