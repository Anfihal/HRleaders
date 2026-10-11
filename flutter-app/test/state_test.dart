import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/core/presentation/resource_state.dart';
import 'package:hrleaders/features/candidates/application/candidate_use_cases.dart';
import 'package:hrleaders/features/candidates/domain/candidates.dart';
import 'package:hrleaders/features/candidates/presentation/candidate_search_bloc.dart';
import 'package:hrleaders/features/auth/presentation/auth_bloc.dart';

final class ControlledCandidates implements CandidateRepository {
  final List<Completer<Page<Candidate>>> requests = [];
  final List<int> offsets = [];
  @override
  Future<Page<Candidate>> search(
    CandidateFilter filter, {
    required int offset,
    required int limit,
  }) {
    offsets.add(offset);
    final request = Completer<Page<Candidate>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<Candidate> details(EntityId id) => throw UnimplementedError();
  @override
  Future<Candidate> myProfile() => throw UnimplementedError();
  @override
  Future<Candidate> update(ProfileDraft draft) => throw UnimplementedError();
  @override
  Future<Candidate> syncFsp() => throw UnimplementedError();
  @override
  Future<Dictionaries> dictionaries() => throw UnimplementedError();
}

void main() {
  test(
    'resource loading, empty, refresh failure and retry preserve data',
    () async {
      var fail = false;
      var data = <int>[];
      final bloc = ResourceBloc<List<int>>(() async {
        if (fail) throw const AppFailure(FailureKind.unavailable, 'offline');
        return data;
      }, isEmpty: (v) => v.isEmpty);
      final phases = <ResourcePhase>[];
      final subscription = bloc.stream.listen((s) => phases.add(s.phase));
      await bloc.load();
      expect(bloc.state.phase, ResourcePhase.empty);
      data = [1];
      await bloc.load();
      fail = true;
      await bloc.load();
      expect(bloc.state.phase, ResourcePhase.failure);
      expect(bloc.state.value, [1]);
      fail = false;
      await bloc.load();
      expect(bloc.state.phase, ResourcePhase.loaded);
      expect(phases, contains(ResourcePhase.refreshing));
      await subscription.cancel();
      await bloc.close();
    },
  );
  test(
    'superseded reads cannot overwrite newer data or emit after disposal',
    () async {
      final first = Completer<int>(), second = Completer<int>();
      var calls = 0;
      final bloc = ResourceBloc<int>(
        () => calls++ == 0 ? first.future : second.future,
      );
      final firstLoad = bloc.load(), secondLoad = bloc.load();
      second.complete(2);
      await secondLoad;
      first.complete(1);
      await firstLoad;
      expect(bloc.state.value, 2);
      await bloc.close();
    },
  );
  test(
    'search ignores stale pages, appends pagination and emits refreshing',
    () async {
      final deps = AppDependencies.demo();
      await deps.auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
      final repository = ControlledCandidates();
      final bloc = CandidateSearchBloc(
        SearchCandidates(repository, deps.access),
      );
      final candidate = Candidate(
        id: EntityId('00000000-0000-4000-8000-000000000200'),
        name: 'Specialist',
        headline: 'Engineer',
      );
      Future<void> tick() => Future<void>.delayed(Duration.zero);
      Page<Candidate> page(int total, {int offset = 0}) =>
          Page(items: [candidate], total: total, offset: offset, limit: 20);
      bloc.add(const SearchRequested(CandidateFilter(skill: 'old')));
      await tick();
      bloc.add(const SearchRequested(CandidateFilter(skill: 'new')));
      await tick();
      repository.requests[1].complete(page(2));
      await tick();
      repository.requests[0].complete(page(99));
      await tick();
      expect(bloc.state.value!.total, 2);
      bloc.add(const LoadNextPage());
      await tick();
      expect(bloc.state.phase, ResourcePhase.loadingMore);
      expect(repository.offsets.last, 1);
      repository.requests[2].complete(page(2, offset: 1));
      await tick();
      expect(bloc.state.value!.items.length, 2);
      expect(bloc.state.value!.hasMore, isFalse);
      bloc.add(const RefreshCandidates());
      await tick();
      expect(bloc.state.phase, ResourcePhase.refreshing);
      repository.requests[3].completeError(
        const AppFailure(FailureKind.unavailable, 'offline'),
      );
      await tick();
      expect(bloc.state.value!.items.length, 2);
      await bloc.close();
      await deps.dispose();
    },
  );
  test(
    'authentication exposes failure, recovery, and session expiration',
    () async {
      final deps = AppDependencies.demo();
      final bloc = deps.authBloc;
      bloc.add(const LoginSubmitted('invalid', 'short'));
      await bloc.stream.firstWhere((s) => s.phase == AuthPhase.failure);
      expect(bloc.state.failure!.kind, FailureKind.validation);
      bloc.add(
        const LoginSubmitted('candidate@demo.hrleaders.example', 'Demo12345'),
      );
      await bloc.stream.firstWhere((s) => s.phase == AuthPhase.authenticated);
      bloc.add(const SessionExpired());
      await bloc.stream.firstWhere((s) => s.phase == AuthPhase.anonymous);
      expect(deps.auth.current, isNull);
      await deps.dispose();
    },
  );
}
