import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../../assessments/domain/assessments.dart';
import '../../auth/domain/auth.dart';
import '../domain/recruiter_cjm.dart';

final class RemoteRecruiterCjmRepository implements RecruiterCjmRepository {
  RemoteRecruiterCjmRepository(this.api, this.auth, this.assessments);

  final ApiClient api;
  final AuthRepository auth;
  final AssessmentRepository assessments;

  @override
  Future<List<TrackedCandidate>> followedCandidates() async {
    final user = auth.current?.user;
    if (user == null) {
      throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated');
    }
    if (!user.can(Permission.viewCandidates)) return const [];
    return List.unmodifiable(
      decodeList(
        await api.request('GET', 'recruiting/tracked-candidates'),
        _trackedCandidate,
      ),
    );
  }

  @override
  Future<List<AssessmentAssignment>> assignments() async => List.unmodifiable(
    decodeList(
      await api.request('GET', 'recruiting/assessment-assignments'),
      _assignment,
    ),
  );

  @override
  Future<TrackedCandidate> follow(
    EntityId candidateId,
  ) async => _trackedCandidate(
    await api.request(
      'PUT',
      'recruiting/tracked-candidates/${Uri.encodeComponent(candidateId.value)}',
    ),
  );

  @override
  Future<void> unfollow(EntityId candidateId) async {
    await api.request(
      'DELETE',
      'recruiting/tracked-candidates/${Uri.encodeComponent(candidateId.value)}',
    );
  }

  @override
  Future<AssessmentAssignment> assign({
    required EntityId candidateId,
    required String disciplineCode,
    required String targetGrade,
  }) async => _assignment(
    await api.request(
      'POST',
      'recruiting/assessment-assignments',
      body: {
        'candidate_id': candidateId.value,
        'discipline_code': disciplineCode,
        'target_grade': targetGrade,
      },
    ),
  );

  @override
  Future<AssessmentAttempt> startAssignment(EntityId assignmentId) async {
    final assigned = (await assignments())
        .where(
          (item) =>
              item.id == assignmentId &&
              item.status == AssessmentAssignmentStatus.assigned,
        )
        .firstOrNull;
    if (assigned == null) {
      throw const AppFailure(
        FailureKind.notFound,
        'assessment_assignment_not_found',
      );
    }
    return assessments.start(assigned.testId, assignmentId: assigned.id.value);
  }

  TrackedCandidate _trackedCandidate(Object? raw) {
    final data = JsonReader(raw);
    return TrackedCandidate(
      candidateId: EntityId(data.string('candidate_id')),
      name: data.string('candidate_name'),
      headline: data.string('headline'),
      followedAt: data.date('followed_at'),
      latestScorePercent: data.optionalDecimal('latest_score_percent'),
      latestAssessmentAt: data.optionalDate('latest_assessment_at'),
    );
  }

  AssessmentAssignment _assignment(Object? raw) {
    final data = JsonReader(raw);
    final attemptId = data.optionalString('attempt_id');
    return AssessmentAssignment(
      id: EntityId(data.string('id')),
      recruiterId: EntityId(data.string('recruiter_id')),
      candidateId: EntityId(data.string('candidate_id')),
      candidateName: data.string('candidate_name'),
      disciplineCode: data.string('discipline_code'),
      targetGrade: data.string('target_grade'),
      status: parseAssignmentStatus(data.string('status')),
      assignedAt: data.date('assigned_at'),
      dueAt: data.optionalDate('due_at'),
      attemptId: attemptId == null ? null : EntityId(attemptId),
      scorePercent: data.optionalDecimal('score_percent'),
    );
  }
}
