import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/data/mock_auth_repository.dart';
import '../../recruiter_cjm/domain/recruiter_cjm.dart';
import '../domain/assessments.dart';

final class MockAssessmentRepository implements AssessmentRepository {
  MockAssessmentRepository(this.store, this.auth);

  final DemoStore store;
  final MockAuthRepository auth;
  @override
  bool get supportsReflection => true;

  static final tests = <AssessmentTest>[
    AssessmentTest(
      id: 'algorithmic::junior',
      title: 'Algorithmic reasoning · Junior',
      description:
          'A short demonstration test about basic algorithmic concepts.',
      discipline: 'algorithmic',
      grade: 'junior',
      durationMinutes: 5,
      questions: const [
        AssessmentQuestion(
          id: 'complexity',
          prompt: 'Which structure provides average O(1) key lookup?',
          options: ['Hash map', 'Sorted list', 'Linked list'],
          correctOption: 0,
          skill: 'Data structures',
        ),
        AssessmentQuestion(
          id: 'iteration',
          prompt:
              'How many iterations does a loop from 0 to 4 (exclusive) make?',
          options: ['4', '5', '3'],
          correctOption: 0,
          skill: 'Reasoning about loops',
        ),
        AssessmentQuestion(
          id: 'search',
          prompt: 'What input does binary search require?',
          options: ['Sorted data', 'A graph', 'A hash function'],
          correctOption: 0,
          skill: 'Search algorithms',
        ),
      ],
    ),
  ];

  EntityId get _candidateId => auth.profileId;

  @override
  Future<List<AssessmentTest>> catalog() async => List.unmodifiable(tests);

  @override
  Future<List<AssessmentAttempt>> attempts() async => List.unmodifiable(
    store.assessmentAttempts
        .where((attempt) => attempt.candidateId == _candidateId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
  );

  @override
  Future<AssessmentAttempt> start(String testId, {String? assignmentId}) async {
    _test(testId);
    if (assignmentId != null) {
      final assignment = store.assessmentAssignments
          .where(
            (item) =>
                item.id.value == assignmentId &&
                item.candidateId == _candidateId &&
                item.testId == testId &&
                item.status == AssessmentAssignmentStatus.assigned,
          )
          .firstOrNull;
      if (assignment == null) {
        throw const AppFailure(
          FailureKind.notFound,
          'assessment_assignment_not_found',
        );
      }
    }
    final active = store.assessmentAttempts.where(
      (item) =>
          item.candidateId == _candidateId &&
          item.testId == testId &&
          item.status == AssessmentStatus.inProgress,
    );
    if (active.isNotEmpty) {
      final attempt = active.last;
      if (assignmentId != null) {
        _replaceAssignment(
          assignmentId,
          (assignment) => assignment.copyWith(
            status: AssessmentAssignmentStatus.inProgress,
            attemptId: attempt.id,
          ),
        );
      }
      return attempt;
    }
    final attempt = AssessmentAttempt(
      id: store.nextId(),
      candidateId: _candidateId,
      testId: testId,
      startedAt: DateTime.now().toUtc(),
      answers: List<int?>.filled(_test(testId).questions.length, null),
      questionIds: _test(testId).questions
          .map((question) => question.id)
          .toList(),
    );
    store.assessmentAttempts.add(attempt);
    if (assignmentId != null) {
      _replaceAssignment(
        assignmentId,
        (assignment) => assignment.copyWith(
          status: AssessmentAssignmentStatus.inProgress,
          attemptId: attempt.id,
        ),
      );
    }
    return attempt;
  }

  @override
  Future<AssessmentAttempt> answer(
    EntityId attemptId,
    int index,
    int option,
  ) async {
    final attempt = _attempt(attemptId);
    final test = _test(attempt.testId);
    if (attempt.status != AssessmentStatus.inProgress ||
        index < 0 ||
        index >= test.questions.length ||
        option < 0 ||
        option >= test.questions[index].options.length) {
      throw const AppFailure(
        FailureKind.validation,
        'invalid_assessment_answer',
      );
    }
    final answers = [...attempt.answers]..[index] = option;
    return _replace(attempt.copyWith(answers: answers));
  }

  @override
  Future<AssessmentReport> complete(EntityId attemptId) async {
    var attempt = _attempt(attemptId);
    if (attempt.status == AssessmentStatus.inProgress) {
      if (attempt.answers.any((answer) => answer == null)) {
        throw const AppFailure(
          FailureKind.validation,
          'assessment_answers_incomplete',
        );
      }
      attempt = _replace(
        attempt.copyWith(
          status: AssessmentStatus.completed,
          completedAt: DateTime.now().toUtc(),
        ),
      );
      final score = _report(attempt).percent;
      if (score != null) {
        attempt = _replace(attempt.copyWith(scorePercent: score.toDouble()));
      }
      final assignment = store.assessmentAssignments
          .where((item) => item.attemptId == attempt.id)
          .firstOrNull;
      if (assignment != null) {
        _replaceAssignment(
          assignment.id.value,
          (item) => item.copyWith(
            status: AssessmentAssignmentStatus.scored,
            scorePercent: score?.toDouble(),
          ),
        );
      }
    }
    return _report(attempt);
  }

  @override
  Future<AssessmentReport> report(EntityId attemptId) async {
    final attempt = _attempt(attemptId);
    if (attempt.status != AssessmentStatus.completed) {
      throw const AppFailure(FailureKind.validation, 'assessment_not_complete');
    }
    return _report(attempt);
  }

  @override
  Future<AssessmentAttempt> saveReflection(
    EntityId attemptId, {
    required String strength,
    required String challenge,
    required String learned,
    required String improve,
    required String nextStep,
  }) async {
    final attempt = _attempt(attemptId);
    if (attempt.status != AssessmentStatus.completed) {
      throw const AppFailure(FailureKind.validation, 'assessment_not_complete');
    }
    validateReflection(
      strength: strength,
      challenge: challenge,
      learned: learned,
      improve: improve,
      nextStep: nextStep,
    );
    return _replace(
      attempt.copyWith(
        reflection: AssessmentReflection(
          strength: strength.trim(),
          challenge: challenge.trim(),
          learned: learned.trim(),
          improve: improve.trim(),
          nextStep: nextStep.trim(),
          savedAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }

  AssessmentAttempt _attempt(EntityId id) {
    final attempt = store.assessmentAttempts
        .where((item) => item.id == id && item.candidateId == _candidateId)
        .firstOrNull;
    if (attempt == null) {
      throw const AppFailure(
        FailureKind.notFound,
        'assessment_attempt_not_found',
      );
    }
    return attempt;
  }

  AssessmentTest _test(String id) =>
      tests.where((test) => test.id == id).firstOrNull ??
      (throw const AppFailure(FailureKind.notFound, 'assessment_not_found'));

  AssessmentAttempt _replace(AssessmentAttempt attempt) {
    final index = store.assessmentAttempts.indexWhere(
      (item) => item.id == attempt.id,
    );
    store.assessmentAttempts[index] = attempt;
    return attempt;
  }

  void _replaceAssignment(
    String id,
    AssessmentAssignment Function(AssessmentAssignment) update,
  ) {
    final index = store.assessmentAssignments.indexWhere(
      (item) => item.id.value == id,
    );
    if (index >= 0) {
      store.assessmentAssignments[index] = update(
        store.assessmentAssignments[index],
      );
    }
  }

  AssessmentReport _report(AssessmentAttempt attempt) {
    final test = _test(attempt.testId);
    final correct = List.generate(test.questions.length, (index) => index)
        .where(
          (index) =>
              attempt.answers[index] == test.questions[index].correctOption,
        )
        .length;
    return AssessmentReport(
      attempt: attempt,
      test: test,
      correctAnswers: correct,
      percent: (correct * 100 / test.questions.length).round(),
      elapsed:
          attempt.completedAt?.difference(attempt.startedAt) ?? Duration.zero,
    );
  }
}

final class UnsupportedAssessmentRepository implements AssessmentRepository {
  const UnsupportedAssessmentRepository();

  @override
  bool get supportsReflection => false;

  Never _unsupported() => throw const AppFailure(
    FailureKind.unsupported,
    'assessment_api_unavailable',
  );

  @override
  Future<List<AssessmentTest>> catalog() async => _unsupported();

  @override
  Future<List<AssessmentAttempt>> attempts() async => _unsupported();

  @override
  Future<AssessmentAttempt> start(
    String testId, {
    String? assignmentId,
  }) async => _unsupported();

  @override
  Future<AssessmentAttempt> answer(
    EntityId attemptId,
    int index,
    int option,
  ) async => _unsupported();

  @override
  Future<AssessmentReport> complete(EntityId attemptId) async => _unsupported();

  @override
  Future<AssessmentReport> report(EntityId attemptId) async => _unsupported();

  @override
  Future<AssessmentAttempt> saveReflection(
    EntityId attemptId, {
    required String strength,
    required String challenge,
    required String learned,
    required String improve,
    required String nextStep,
  }) async => _unsupported();
}
