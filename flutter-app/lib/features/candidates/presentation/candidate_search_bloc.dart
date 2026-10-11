import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/presentation/resource_state.dart';
import '../application/candidate_use_cases.dart';
import '../domain/candidates.dart';

sealed class CandidateSearchEvent {
  const CandidateSearchEvent();
}

final class SearchRequested extends CandidateSearchEvent {
  const SearchRequested([this.filter = const CandidateFilter()]);
  final CandidateFilter filter;
}

final class LoadNextPage extends CandidateSearchEvent {
  const LoadNextPage();
}

final class RefreshCandidates extends CandidateSearchEvent {
  const RefreshCandidates();
}

final class CandidateSearchBloc
    extends Bloc<CandidateSearchEvent, ResourceState<Page<Candidate>>> {
  CandidateSearchBloc(this.search)
    : super(const ResourceState(ResourcePhase.initial)) {
    on<SearchRequested>(
      (event, emit) => _first(event.filter, emit),
      transformer: restartable(),
    );
    on<RefreshCandidates>(
      (event, emit) => _first(filter, emit, refreshing: true),
      transformer: restartable(),
    );
    on<LoadNextPage>(_next, transformer: droppable());
  }
  final SearchCandidates search;
  CandidateFilter filter = const CandidateFilter();
  int _revision = 0;
  Future<void> _first(
    CandidateFilter nextFilter,
    Emitter<ResourceState<Page<Candidate>>> emit, {
    bool refreshing = false,
  }) async {
    final revision = ++_revision;
    filter = nextFilter;
    emit(
      ResourceState(
        refreshing && state.value != null
            ? ResourcePhase.refreshing
            : ResourcePhase.loading,
        value: state.value,
      ),
    );
    try {
      final page = await search(nextFilter);
      if (emit.isDone || revision != _revision) return;
      emit(
        ResourceState(
          page.items.isEmpty ? ResourcePhase.empty : ResourcePhase.loaded,
          value: page,
        ),
      );
    } on AppFailure catch (error) {
      if (!emit.isDone && revision == _revision) {
        emit(
          ResourceState(
            ResourcePhase.failure,
            value: state.value,
            failure: error,
          ),
        );
      }
    }
  }

  Future<void> _next(
    LoadNextPage event,
    Emitter<ResourceState<Page<Candidate>>> emit,
  ) async {
    final old = state.value;
    if (old == null || !old.hasMore || state.busy) return;
    final revision = _revision;
    emit(ResourceState(ResourcePhase.loadingMore, value: old));
    try {
      final page = await search(filter, offset: old.items.length);
      if (emit.isDone || revision != _revision) return;
      final combined = Page(
        items: [...old.items, ...page.items],
        total: page.total,
        offset: 0,
        limit: page.limit,
      );
      emit(ResourceState(ResourcePhase.loaded, value: combined));
    } on AppFailure catch (error) {
      if (!emit.isDone && revision == _revision) {
        emit(ResourceState(ResourcePhase.failure, value: old, failure: error));
      }
    }
  }
}
