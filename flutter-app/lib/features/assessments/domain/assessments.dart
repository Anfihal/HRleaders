import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';

final class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.correctOption,
    required this.skill,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int? correctOption;
  final String skill;
}

final class AssessmentTest {
  const AssessmentTest({
    required this.id,
    required this.title,
    required this.description,
    required this.discipline,
    required this.grade,
    this.durationMinutes,
    required this.questions,
    this.employerAssigned = false,
  });

  final String id;
  final String title;
  final String description;
  final String discipline;
  final String grade;
  final int? durationMinutes;
  final List<AssessmentQuestion> questions;
  final bool employerAssigned;

  AssessmentTest copyWith({List<AssessmentQuestion>? questions}) =>
      AssessmentTest(
        id: id,
        title: title,
        description: description,
        discipline: discipline,
        grade: grade,
        durationMinutes: durationMinutes,
        questions: questions ?? this.questions,
        employerAssigned: employerAssigned,
      );
}

enum AssessmentStatus { inProgress, submitted, completed, expired }

final class AssessmentReflection {
  const AssessmentReflection({
    required this.strength,
    required this.challenge,
    required this.learned,
    required this.improve,
    required this.nextStep,
    required this.savedAt,
  });

  final String strength;
  final String challenge;
  final String learned;
  final String improve;
  final String nextStep;
  final DateTime savedAt;
}

final class AssessmentAttempt {
  AssessmentAttempt({
    required this.id,
    required this.candidateId,
    required this.testId,
    required this.startedAt,
    required List<int?> answers,
    List<bool?> correctness = const [],
    List<String>? questionIds,
    this.status = AssessmentStatus.inProgress,
    this.completedAt,
    this.reflection,
    this.scorePercent,
    this.timeSpentSeconds,
  }) : answers = List.unmodifiable(answers),
       correctness = List.unmodifiable(correctness),
       questionIds = List.unmodifiable(questionIds ?? const []);

  final EntityId id;
  final EntityId candidateId;
  final String testId;
  final DateTime startedAt;
  final List<int?> answers;
  final List<bool?> correctness;
  final List<String> questionIds;
  final AssessmentStatus status;
  final DateTime? completedAt;
  final AssessmentReflection? reflection;
  final double? scorePercent;
  final int? timeSpentSeconds;

  AssessmentAttempt copyWith({
    List<int?>? answers,
    List<bool?>? correctness,
    List<String>? questionIds,
    AssessmentStatus? status,
    DateTime? completedAt,
    AssessmentReflection? reflection,
    double? scorePercent,
    int? timeSpentSeconds,
  }) => AssessmentAttempt(
    id: id,
    candidateId: candidateId,
    testId: testId,
    startedAt: startedAt,
    answers: answers ?? this.answers,
    correctness: correctness ?? this.correctness,
    questionIds: questionIds ?? this.questionIds,
    status: status ?? this.status,
    completedAt: completedAt ?? this.completedAt,
    reflection: reflection ?? this.reflection,
    scorePercent: scorePercent ?? this.scorePercent,
    timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
  );
}

final class AssessmentReport {
  const AssessmentReport({
    required this.attempt,
    required this.test,
    this.correctAnswers,
    this.percent,
    this.elapsed,
    this.awaitingScore = false,
  });

  final AssessmentAttempt attempt;
  final AssessmentTest test;
  final int? correctAnswers;
  final int? percent;
  final Duration? elapsed;
  final bool awaitingScore;
  bool get hasSkillBreakdown =>
      attempt.correctness.any((value) => value != null) ||
      test.questions.any((question) => question.correctOption != null);

  List<String> get strengths => [
    for (var i = 0; i < test.questions.length; i++)
      if (attempt.correctness.length > i && attempt.correctness[i] == true ||
          attempt.answers[i] == test.questions[i].correctOption &&
              test.questions[i].correctOption != null)
        test.questions[i].skill,
  ];
  List<String> get developmentAreas => [
    for (var i = 0; i < test.questions.length; i++)
      if (attempt.correctness.length > i && attempt.correctness[i] == false ||
          attempt.answers[i] != test.questions[i].correctOption &&
              test.questions[i].correctOption != null)
        test.questions[i].skill,
  ];
}

abstract interface class AssessmentRepository {
  bool get supportsReflection;
  Future<List<AssessmentTest>> catalog();
  Future<List<AssessmentAttempt>> attempts();
  Future<AssessmentAttempt> start(String testId, {String? assignmentId});
  Future<AssessmentAttempt> answer(EntityId attemptId, int index, int option);
  Future<AssessmentReport> complete(EntityId attemptId);
  Future<AssessmentReport> report(EntityId attemptId);
  Future<AssessmentAttempt> saveReflection(
    EntityId attemptId, {
    required String strength,
    required String challenge,
    required String learned,
    required String improve,
    required String nextStep,
  });
}

String validateReflection({
  required String strength,
  required String challenge,
  required String learned,
  required String improve,
  required String nextStep,
}) {
  final values = [strength, challenge, learned, improve, nextStep];
  if (values.any((value) => value.trim().isEmpty)) {
    throw const AppFailure(FailureKind.validation, 'reflection_required');
  }
  if (values.any((value) => value.trim().length > 1000)) {
    throw const AppFailure(FailureKind.validation, 'reflection_too_long');
  }
  return 'ok';
}
