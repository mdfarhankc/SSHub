import 'package:sshub/features/snippets/data/datasources/snippet_datasource.dart';
import 'package:sshub/features/snippets/data/models/snippet_model.dart';
import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';

class SnippetRepositoryImpl implements SnippetRepository {
  final SnippetDatasource _localDatasource;
  const SnippetRepositoryImpl(this._localDatasource);

  @override
  Future<List<Snippet>> getSnippets() => _localDatasource.load();

  @override
  Future<void> addSnippet(Snippet snippet) async {
    final snippets = await _localDatasource.load();
    await _localDatasource.save([
      ...snippets,
      SnippetModel.fromEntity(snippet),
    ]);
  }

  @override
  Future<void> updateSnippet(Snippet snippet) async {
    final snippets = await _localDatasource.load();
    await _localDatasource.save([
      for (final s in snippets)
        if (s.id == snippet.id) SnippetModel.fromEntity(snippet) else s,
    ]);
  }

  @override
  Future<void> deleteSnippet(String id) async {
    final snippets = await _localDatasource.load();
    await _localDatasource.save(snippets.where((s) => s.id != id).toList());
  }

  @override
  Future<void> clearAll() => _localDatasource.clear();
}
