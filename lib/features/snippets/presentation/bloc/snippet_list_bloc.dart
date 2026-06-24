import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/snippets/domain/entities/snippet.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';

part 'snippet_list_state.dart';
part 'snippet_list_event.dart';

class SnippetListBloc extends Bloc<SnippetListEvent, SnippetListState> {
  final SnippetRepository _repository;

  SnippetListBloc(this._repository) : super(const SnippetListState()) {
    on<SnippetListLoaded>(_onLoaded);
    on<SnippetAdded>(_onAdded);
    on<SnippetUpdated>(_onUpdated);
    on<SnippetDeleted>(_onDeleted);
  }

  Future<void> _onLoaded(
    SnippetListLoaded event,
    Emitter<SnippetListState> emit,
  ) async {
    emit(state.copyWith(status: SnippetListStatus.loading));
    try {
      final snippets = await _repository.getSnippets();
      emit(
        state.copyWith(status: SnippetListStatus.success, snippets: snippets),
      );
    } catch (e) {
      emit(state.copyWith(status: SnippetListStatus.failure));
    }
  }

  Future<void> _onAdded(
    SnippetAdded event,
    Emitter<SnippetListState> emit,
  ) async {
    try {
      await _repository.addSnippet(event.snippet);
      emit(state.copyWith(snippets: [...state.snippets, event.snippet]));
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not add snippet"));
    }
  }

  Future<void> _onUpdated(
    SnippetUpdated event,
    Emitter<SnippetListState> emit,
  ) async {
    try {
      await _repository.updateSnippet(event.snippet);
      emit(
        state.copyWith(
          snippets: [
            for (final s in state.snippets)
              if (s.id == event.snippet.id) event.snippet else s,
          ],
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not update snippet"));
    }
  }

  Future<void> _onDeleted(
    SnippetDeleted event,
    Emitter<SnippetListState> emit,
  ) async {
    try {
      await _repository.deleteSnippet(event.id);
      emit(
        state.copyWith(
          snippets: state.snippets.where((s) => s.id != event.id).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: "Could not delete snippet"));
    }
  }
}
