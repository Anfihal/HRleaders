import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../assessments/domain/assessments.dart';

enum AssessmentAssignmentStatus {
  assigned,
  inProgress,
  submitted,
  scored,
  expired,
}

final class TrackedCandidate {
  const TrackedCandidate({
    required this.candidateId,
    required this.name,
    required this.headline,
    required this.followedAt,
    this.latestScorePercent,
    this.latestAssessmentAt,
  });

  final EntityId candidateId;
  final String name;
  final String headline;
  final DateTime followedAt;
  final double? latestScorePercent;
  final DateTime? latestAssessmentAt;
}

final class AssessmentAssignment {
  const AssessmentAssignment({
    required this.id,
    required this.recruiterId,
    required this.candidateId,
    required this.candidateName,
    required this.disciplineCode,
    required this.targetGrade,
    required this.status,
    required this.assignedAt,
    this.dueAt,
    this.attemptId,
    this.scorePercent,
  });

  final EntityId id;
  final EntityId recruiterId;
  final EntityId candidateId;
  final String candidateName;
  final String disciplineCode;
  final String targetGrade;
  final AssessmentAssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? dueAt;
  final EntityId? attemptId;
  final double? scorePercent;

  String get testId => '$disciplineCode::$targetGrade';

  AssessmentAssignment copyWith({
    AssessmentAssignmentStatus? status,
    DateTime? dueAt,
    EntityId? attemptId,
    double? scorePercent,
  }) => AssessmentAssignment(
    id: id,
    recruiterId: recruiterId,
    candidateId: candidateId,
    candidateName: candidateName,
    disciplineCode: disciplineCode,
    targetGrade: targetGrade,
    status: status ?? this.status,
    assignedAt: assignedAt,
    dueAt: dueAt ?? this.dueAt,
    attemptId: attemptId ?? this.attemptId,
    scorePercent: scorePercent ?? this.scorePercent,
  );
}

abstract interface class RecruiterCjmRepository {
  Future<List<TrackedCandidate>> followedCandidates();
  Future<List<AssessmentAssignment>> assignments();
  Future<TrackedCandidate> follow(EntityId candidateId);
  Future<void> unfollow(EntityId candidateId);
  Future<AssessmentAssignment> assign({
    required EntityId candidateId,
    required String disciplineCode,
    required String targetGrade,
  });
  Future<AssessmentAttempt> startAssignment(EntityId assignmentId);
}

AssessmentAssignmentStatus parseAssignmentStatus(String value) =>
    switch (value) {
      'assigned' => AssessmentAssignmentStatus.assigned,
      'in_progress' => AssessmentAssignmentStatus.inProgress,
      'submitted' => AssessmentAssignmentStatus.submitted,
      'scored' => AssessmentAssignmentStatus.scored,
      'expired' => AssessmentAssignmentStatus.expired,
      _ => throw const AppFailure(
        FailureKind.malformed,
        'invalid_assessment_assignment_status',
      ),
    };
