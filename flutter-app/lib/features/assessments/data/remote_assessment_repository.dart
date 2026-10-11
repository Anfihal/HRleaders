import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../../auth/domain/auth.dart';
import '../domain/assessments.dart';

final class RemoteAssessmentRepository implements AssessmentRepository {
  RemoteAssessmentRepository(this.api, this.auth);

  final ApiClient api;
  final AuthRepository auth;
  final Map<String, AssessmentTest> _tests = {};

  @override
  bool get supportsReflection => false;

  @override
  Future<List<AssessmentTest>> catalog() async {
    final questions =
        decodeList(
          await api.request('GET', 'assessments/questions'),
          _question,
        ).where(
          (question) =>
              question.options.isNotEmpty && question.correctOption == null,
        );
    final grouped = <String, List<AssessmentQuestion>>{};
    final metadata = <String, (String, String)>{};
    for (final question in questions) {
      final raw = _rawQuestions[question.id]!;
      final discipline = raw.string('discipline_code');
      final grade = raw.string('target_grade');
      final id = _testId(discipline, grade);
      grouped.putIfAbsent(id, () => []).add(question);
      metadata[id] = (discipline, grade);
    }
    _tests
      ..clear()
      ..addEntries(
        grouped.entries.map((entry) {
          final (discipline, grade) = metadata[entry.key]!;
          return MapEntry(
            entry.key,
            AssessmentTest(
              id: entry.key,
              title: '$discipline · $grade',
              description: 'Assessment questions supplied by HRleaders API.',
              discipline: discipline,
              grade: grade,
              questions: List.unmodifiable(entry.value),
            ),
          );
        }),
      );
    return List.unmodifiable(_tests.values);
  }

  final Map<String, JsonReader> _rawQuestions = {};

  AssessmentQuestion _question(Object? raw) {
    final data = JsonReader(raw);
    final type = data.string('question_type');
    final options = type == 'single_choice'
        ? data.strings('options')
        : const <String>[];
    final question = AssessmentQuestion(
      id: data.string('id'),
      prompt: data.string('body'),
      options: options,
      skill: data.strings('skills').join(', '),
    );
    if (options.isNotEmpty) _rawQuestions[question.id] = data;
    return question;
  }

  String _testId(String discipline, String grade) => '$discipline::$grade';

  @override
  Future<List<AssessmentAttempt>> attempts() async {
    final rawAttempts = decodeList(
      await api.request('GET', 'assessments/attempts'),
      (raw) => JsonReader(raw).string('id'),
    );
    final result = <AssessmentAttempt>[];
    for (final id in rawAttempts) {
      final raw = await api.request(
        'GET',
        'assessments/attempts/${Uri.encodeComponent(id)}',
      );
      final attempt = _attempt(raw);
      result.add(attempt);
    }
    result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(result);
  }

  @override
  Future<AssessmentAttempt> start(String testId, {String? assignmentId}) async {
    final test = _test(testId);
    final body = <String, Object?>{
      'discipline_code': test.discipline,
      'target_grade': test.grade,
    };
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    final attempt = _attempt(
      await api.request('POST', 'assessments/attempts/start', body: body),
    );
    return attempt;
  }

  @override
  Future<AssessmentAttempt> answer(
    EntityId attemptId,
    int index,
    int option,
  ) async {
    final attempt = await _getAttempt(attemptId);
    final test = _test(attempt.testId);
    if (attempt.status != AssessmentStatus.inProgress ||
        index < 0 ||
        index >= attempt.questionIds.length ||
        option < 0 ||
        option >= test.questions[index].options.length) {
      throw const AppFailure(
        FailureKind.validation,
        'invalid_assessment_answer',
      );
    }
    final questionId = attempt.questionIds[index];
    final question = test.questions
        .where((item) => item.id == questionId)
        .firstOrNull;
    if (question == null) {
      throw const AppFailure(
        FailureKind.malformed,
        'assessment_question_missing',
      );
    }
    return _attempt(
      await api.request(
        'POST',
        'assessments/attempts/${Uri.encodeComponent(attemptId.value)}/answers',
        body: {'question_id': questionId, 'answer': question.options[option]},
      ),
    );
  }

  @override
  Future<AssessmentReport> complete(EntityId attemptId) async {
    final response = await api.request(
      'POST',
      'assessments/attempts/${Uri.encodeComponent(attemptId.value)}/submit',
    );
    return _report(_attempt(response));
  }

  @override
  Future<AssessmentReport> report(EntityId attemptId) async =>
      _report(await _getAttempt(attemptId));

  @override
  Future<AssessmentAttempt> saveReflection(
    EntityId attemptId, {
    required String strength,
    required String challenge,
    required String learned,
    required String improve,
    required String nextStep,
  }) async {
    throw const AppFailure(
      FailureKind.unsupported,
      'assessment_reflection_api_unavailable',
    );
  }

  AssessmentTest _test(String testId) =>
      _tests[testId] ??
      (throw const AppFailure(FailureKind.notFound, 'assessment_not_found'));

  Future<AssessmentAttempt> _getAttempt(EntityId id) async => _attempt(
    await api.request(
      'GET',
      'assessments/attempts/${Uri.encodeComponent(id.value)}',
    ),
  );

  AssessmentAttempt _attempt(Object? raw) {
    final data = JsonReader(raw);
    final discipline = data.string('discipline_code');
    final grade = data.string('target_grade');
    final test = _test(_testId(discipline, grade));
    final questionIds = data.strings('question_ids');
    final answerObjects = data.list('answers').map(JsonReader.new).toList();
    final answers = <int?>[];
    final correctness = <bool?>[];
    for (final questionId in questionIds) {
      final answer = answerObjects
          .where((entry) => entry.string('question_id') == questionId)
          .firstOrNull;
      if (answer == null) {
        answers.add(null);
        correctness.add(null);
        continue;
      }
      final response = answer.string('answer');
      final options = test.questions
          .where((question) => question.id == questionId)
          .firstOrNull
          ?.options;
      final optionIndex = options?.indexOf(response) ?? -1;
      answers.add(optionIndex < 0 ? null : optionIndex);
      correctness.add(
        answer.data['is_correct'] == null ? null : answer.boolean('is_correct'),
      );
    }
    final rawStatus = data.string('status');
    final status = switch (rawStatus) {
      'in_progress' => AssessmentStatus.inProgress,
      'submitted' => AssessmentStatus.submitted,
      'scored' => AssessmentStatus.completed,
      'expired' => AssessmentStatus.expired,
      _ => throw const AppFailure(
        FailureKind.malformed,
        'invalid_attempt_status',
      ),
    };
    return AssessmentAttempt(
      id: EntityId(data.string('id')),
      candidateId:
          auth.current?.user.id ??
          (throw const AppFailure(
            FailureKind.unauthenticated,
            'unauthenticated',
          )),
      testId: test.id,
      startedAt: data.date('started_at'),
      answers: answers,
      correctness: correctness,
      questionIds: questionIds,
      status: status,
      completedAt:
          data.optionalDate('scored_at') ?? data.optionalDate('submitted_at'),
      scorePercent: data.optionalDecimal('score_percent'),
      timeSpentSeconds: data.optionalInteger('time_spent_seconds'),
    );
  }

  AssessmentReport _report(AssessmentAttempt attempt) {
    if (attempt.status == AssessmentStatus.inProgress ||
        attempt.status == AssessmentStatus.expired) {
      throw const AppFailure(FailureKind.validation, 'assessment_not_complete');
    }
    final fullTest = _test(attempt.testId);
    final selected = attempt.questionIds
        .map(
          (id) => fullTest.questions
              .where((question) => question.id == id)
              .firstOrNull,
        )
        .whereType<AssessmentQuestion>()
        .toList();
    final test = fullTest.copyWith(
      questions: selected.isEmpty ? fullTest.questions : selected,
    );
    final correct =
        attempt.correctness.isNotEmpty &&
            attempt.correctness.every((value) => value != null)
        ? attempt.correctness.where((value) => value == true).length
        : null;
    return AssessmentReport(
      attempt: attempt,
      test: test,
      correctAnswers: correct,
      percent: attempt.scorePercent?.round(),
      elapsed: attempt.timeSpentSeconds == null
          ? null
          : Duration(seconds: attempt.timeSpentSeconds!),
      awaitingScore: attempt.status == AssessmentStatus.submitted,
    );
  }
}
