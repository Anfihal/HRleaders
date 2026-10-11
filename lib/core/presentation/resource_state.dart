import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_failure.dart';

enum ResourcePhase {
  initial,
  loading,
  loaded,
  empty,
  refreshing,
  loadingMore,
  saving,
  failure,
}

final class ResourceState<T> {
  const ResourceState(
    this.phase, {
    this.value,
    this.failure,
    this.saved = false,
  });
  final ResourcePhase phase;
  final T? value;
  final AppFailure? failure;
  final bool saved;
  bool get busy => {
    ResourcePhase.loading,
    ResourcePhase.refreshing,
    ResourcePhase.loadingMore,
    ResourcePhase.saving,
  }.contains(phase);
}

/// Reusable orchestration for independent read models. Receives use cases only.
class ResourceBloc<T> extends Cubit<ResourceState<T>> {
  ResourceBloc(this.loadData, {this.isEmpty})
    : super(ResourceState<T>(ResourcePhase.initial));
  final Future<T> Function() loadData;
  final bool Function(T)? isEmpty;
  int _revision = 0;
  Future<void> load() async {
    final revision = ++_revision;
    emit(
      ResourceState(
        state.value == null ? ResourcePhase.loading : ResourcePhase.refreshing,
        value: state.value,
      ),
    );
    try {
      final value = await loadData();
      if (isClosed || revision != _revision) return;
      emit(
        ResourceState(
          isEmpty?.call(value) ?? false
              ? ResourcePhase.empty
              : ResourcePhase.loaded,
          value: value,
        ),
      );
    } on AppFailure catch (error) {
      if (!isClosed && revision == _revision) {
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

  Future<void> mutate(Future<void> Function() operation) async {
    if (state.busy) return;
    emit(ResourceState(ResourcePhase.saving, value: state.value));
    try {
      await operation();
      if (!isClosed) await load();
    } on AppFailure catch (error) {
      if (!isClosed) {
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

  @override
  Future<void> close() {
    _revision++;
    return super.close();
  }
}
