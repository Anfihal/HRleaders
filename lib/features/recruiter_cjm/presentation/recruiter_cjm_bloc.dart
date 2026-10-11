import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../assessments/domain/assessments.dart';
import '../domain/recruiter_cjm.dart';

final class RecruiterCjmState {
  const RecruiterCjmState({
    this.loading = false,
    this.saving = false,
    this.followed = const [],
    this.assignments = const [],
    this.tests = const [],
    this.failure,
  });

  final bool loading;
  final bool saving;
  final List<TrackedCandidate> followed;
  final List<AssessmentAssignment> assignments;
  final List<AssessmentTest> tests;
  final AppFailure? failure;
}

final class RecruiterCjmBloc extends Cubit<RecruiterCjmState> {
  RecruiterCjmBloc(this.repository, this.assessments)
    : super(const RecruiterCjmState());

  final RecruiterCjmRepository repository;
  final AssessmentRepository assessments;

  Future<void> load() async {
    emit(
      RecruiterCjmState(
        loading: true,
        followed: state.followed,
        assignments: state.assignments,
        tests: state.tests,
      ),
    );
    try {
      final values = await Future.wait([
        repository.followedCandidates(),
        repository.assignments(),
        assessments.catalog(),
      ]);
      if (!isClosed) {
        emit(
          RecruiterCjmState(
            followed: values[0] as List<TrackedCandidate>,
            assignments: values[1] as List<AssessmentAssignment>,
            tests: values[2] as List<AssessmentTest>,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(RecruiterCjmState(failure: error));
    }
  }

  Future<void> follow(EntityId candidateId) async {
    await _mutate(() => repository.follow(candidateId));
  }

  Future<void> unfollow(EntityId candidateId) async {
    await _mutate(() => repository.unfollow(candidateId));
  }

  Future<void> assign({
    required EntityId candidateId,
    required String disciplineCode,
    required String targetGrade,
  }) async {
    await _mutate(
      () => repository.assign(
        candidateId: candidateId,
        disciplineCode: disciplineCode,
        targetGrade: targetGrade,
      ),
    );
  }

  Future<AssessmentAttempt?> startAssignment(EntityId assignmentId) async {
    emit(_copy(saving: true, clearFailure: true));
    try {
      final attempt = await repository.startAssignment(assignmentId);
      await _refresh();
      return attempt;
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(saving: false, failure: error));
      return null;
    }
  }

  Future<void> _mutate(Future<Object?> Function() action) async {
    emit(_copy(saving: true, clearFailure: true));
    try {
      await action();
      await _refresh();
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(saving: false, failure: error));
    }
  }

  Future<void> _refresh() async {
    final values = await Future.wait([
      repository.followedCandidates(),
      repository.assignments(),
    ]);
    if (!isClosed) {
      emit(
        RecruiterCjmState(
          followed: values[0] as List<TrackedCandidate>,
          assignments: values[1] as List<AssessmentAssignment>,
          tests: state.tests,
        ),
      );
    }
  }

  RecruiterCjmState _copy({
    bool? saving,
    AppFailure? failure,
    bool clearFailure = false,
  }) => RecruiterCjmState(
    loading: state.loading,
    saving: saving ?? state.saving,
    followed: state.followed,
    assignments: state.assignments,
    tests: state.tests,
    failure: clearFailure ? null : failure ?? state.failure,
  );
}
