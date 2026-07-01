import 'package:sshub/features/snippets/data/models/snippet_model.dart';

abstract interface class SnippetDatasource {
  Future<List<SnippetModel>> load();
  Future<void> save(List<SnippetModel> snippets);
  Future<void> clear();
}
