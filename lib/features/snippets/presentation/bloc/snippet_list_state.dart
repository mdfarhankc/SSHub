part of 'snippet_list_bloc.dart';

enum SnippetListStatus { initial, loading, success, failure }

class SnippetListState extends Equatable {
  final SnippetListStatus status;
  final List<Snippet> snippets;
  final String? errorMessage;
  const SnippetListState({
    this.status = SnippetListStatus.initial,
    this.snippets = const [],
    this.errorMessage,
  });

  SnippetListState copyWith({
    SnippetListStatus? status,
    List<Snippet>? snippets,
    String? errorMessage,
  }) => SnippetListState(
    status: status ?? this.status,
    snippets: snippets ?? this.snippets,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, snippets, errorMessage];
}
