import 'package:sshub/features/snippets/domain/entities/snippet.dart';

class SnippetModel extends Snippet {
  const SnippetModel({
    required super.id,
    required super.label,
    required super.value,
  });

  factory SnippetModel.fromJson(Map<String, dynamic> json) => SnippetModel(
    id: json['id'] as String,
    label: json['label'] as String,
    value: json['value'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'value': value};

  factory SnippetModel.fromEntity(Snippet e) =>
      SnippetModel(id: e.id, label: e.label, value: e.value);
}
