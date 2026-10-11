import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../domain/assessments.dart';

final class AssessmentState {
  const AssessmentState({
    this.loading = false,
    this.saving = false,
    this.tests = const [],
    this.attempts = const [],
    this.selectedAttempt,
    this.report,
    this.failure,
    this.saved = false,
  });

  final bool loading;
  final bool saving;
  final List<AssessmentTest> tests;
  final List<AssessmentAttempt> attempts;
  final AssessmentAttempt? selectedAttempt;
  final AssessmentReport? report;
  final AppFailure? failure;
  final bool saved;
}

final class AssessmentBloc extends Cubit<AssessmentState> {
  AssessmentBloc(this.repository) : super(const AssessmentState());
  final AssessmentRepository repository;

  Future<void> load() async {
    emit(AssessmentState(loading: true, attempts: state.attempts));
    try {
      final results = await Future.wait([
        repository.catalog(),
        repository.attempts(),
      ]);
      if (!isClosed) {
        emit(
          AssessmentState(
            tests: results[0] as List<AssessmentTest>,
            attempts: results[1] as List<AssessmentAttempt>,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(AssessmentState(failure: error));
    }
  }

  Future<void> start(String testId) async {
    emit(_copy(state, saving: true, clearFailure: true));
    try {
      final attempt = await repository.start(testId);
      final attempts = await repository.attempts();
      if (!isClosed) {
        emit(
          _copy(
            state,
            saving: false,
            attempts: attempts,
            selectedAttempt: attempt,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, saving: false, failure: error));
    }
  }

  Future<void> openAttempt(EntityId id) async {
    emit(_copy(state, loading: true, clearFailure: true));
    try {
      final results = await Future.wait([
        repository.catalog(),
        repository.attempts(),
      ]);
      final tests = results[0] as List<AssessmentTest>;
      final attempts = results[1] as List<AssessmentAttempt>;
      final attempt = attempts.where((item) => item.id == id).firstOrNull;
      if (attempt == null) {
        throw const AppFailure(
          FailureKind.notFound,
          'assessment_attempt_not_found',
        );
      }
      if (!isClosed) {
        emit(
          AssessmentState(
            tests: tests,
            attempts: attempts,
            selectedAttempt: attempt,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, loading: false, failure: error));
    }
  }

  Future<void> answer(int index, int option) async {
    final attempt = state.selectedAttempt;
    if (attempt == null || state.saving) return;
    emit(_copy(state, saving: true, clearFailure: true));
    try {
      final updated = await repository.answer(attempt.id, index, option);
      final attempts = await repository.attempts();
      if (!isClosed) {
        emit(
          _copy(
            state,
            saving: false,
            attempts: attempts,
            selectedAttempt: updated,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, saving: false, failure: error));
    }
  }

  Future<void> complete() async {
    final attempt = state.selectedAttempt;
    if (attempt == null || state.saving) return;
    emit(_copy(state, saving: true, clearFailure: true));
    try {
      final report = await repository.complete(attempt.id);
      final attempts = await repository.attempts();
      final updated = attempts.where((item) => item.id == attempt.id).first;
      if (!isClosed) {
        emit(
          _copy(
            state,
            saving: false,
            attempts: attempts,
            selectedAttempt: updated,
            report: report,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, saving: false, failure: error));
    }
  }

  Future<void> loadReport(EntityId id) async {
    emit(_copy(state, loading: true, clearFailure: true));
    try {
      final tests = await repository.catalog();
      final report = await repository.report(id);
      final attempts = await repository.attempts();
      if (!isClosed) {
        emit(
          _copy(
            state,
            loading: false,
            tests: tests,
            attempts: attempts,
            selectedAttempt: report.attempt,
            report: report,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, loading: false, failure: error));
    }
  }

  Future<void> saveReflection({
    required String strength,
    required String challenge,
    required String learned,
    required String improve,
    required String nextStep,
  }) async {
    final attempt = state.selectedAttempt;
    if (attempt == null || state.saving) return;
    emit(_copy(state, saving: true, clearFailure: true));
    try {
      final updated = await repository.saveReflection(
        attempt.id,
        strength: strength,
        challenge: challenge,
        learned: learned,
        improve: improve,
        nextStep: nextStep,
      );
      final attempts = await repository.attempts();
      final report = await repository.report(attempt.id);
      if (!isClosed) {
        emit(
          _copy(
            state,
            saving: false,
            attempts: attempts,
            selectedAttempt: updated,
            report: report,
            saved: true,
          ),
        );
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(_copy(state, saving: false, failure: error));
    }
  }

  AssessmentState _copy(
    AssessmentState source, {
    bool? loading,
    bool? saving,
    List<AssessmentTest>? tests,
    List<AssessmentAttempt>? attempts,
    AssessmentAttempt? selectedAttempt,
    AssessmentReport? report,
    AppFailure? failure,
    bool? saved,
    bool clearFailure = false,
  }) => AssessmentState(
    loading: loading ?? source.loading,
    saving: saving ?? source.saving,
    tests: tests ?? source.tests,
    attempts: attempts ?? source.attempts,
    selectedAttempt: selectedAttempt ?? source.selectedAttempt,
    report: report ?? source.report,
    failure: clearFailure ? null : failure ?? source.failure,
    saved: saved ?? source.saved,
  );
}
