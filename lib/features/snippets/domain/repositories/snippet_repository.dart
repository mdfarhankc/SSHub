import 'package:sshub/features/snippets/domain/entities/snippet.dart';

abstract interface class SnippetRepository {
  Future<List<Snippet>> getSnippets();
  Future<void> addSnippet(Snippet snippet);
  Future<void> updateSnippet(Snippet snippet);
  Future<void> deleteSnippet(String id);
  Future<void> clearAll();
}
