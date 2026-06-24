part of 'snippet_list_bloc.dart';

sealed class SnippetListEvent {}

final class SnippetListLoaded extends SnippetListEvent {}

final class SnippetAdded extends SnippetListEvent {
  final Snippet snippet;
  SnippetAdded(this.snippet);
}

final class SnippetUpdated extends SnippetListEvent {
  final Snippet snippet;
  SnippetUpdated(this.snippet);
}

final class SnippetDeleted extends SnippetListEvent {
  final String id;
  SnippetDeleted(this.id);
}
