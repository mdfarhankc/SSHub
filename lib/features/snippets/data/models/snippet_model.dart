import 'package:sshub/features/snippets/domain/entities/snippet.dart';

class SnippetModel extends Snippet {
  const SnippetModel({
    required super.id,
    required super.label,
    required super.value,
    super.type,
    super.pinned,
  });

  factory SnippetModel.fromJson(Map<String, dynamic> json) => SnippetModel(
    id: json['id'] as String,
    label: json['label'] as String,
    value: json['value'] as String? ?? '',
    // Snippets saved before the type field existed stay secret, so nothing
    // that was hidden becomes visible on upgrade.
    type: _typeFrom(json['type'] as String?),
    pinned: json['pinned'] as bool? ?? false,
  );

  static SnippetType _typeFrom(String? raw) =>
      raw == 'command' ? SnippetType.command : SnippetType.secret;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'type': type.name,
    'pinned': pinned,
  };

  factory SnippetModel.fromEntity(Snippet e) => SnippetModel(
    id: e.id,
    label: e.label,
    value: e.value,
    type: e.type,
    pinned: e.pinned,
  );
}
