import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../assessments/domain/assessments.dart';
import '../../auth/data/mock_auth_repository.dart';
import '../../auth/domain/auth.dart';
import '../domain/recruiter_cjm.dart';

final class MockRecruiterCjmRepository implements RecruiterCjmRepository {
  MockRecruiterCjmRepository(this.store, this.auth, this.assessments);

  final DemoStore store;
  final MockAuthRepository auth;
  final AssessmentRepository assessments;

  User get _user =>
      auth.current?.user ??
      (throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated'));

  bool get _isRecruiter => _user.can(Permission.viewCandidates);

  @override
  Future<List<TrackedCandidate>> followedCandidates() async {
    if (!_isRecruiter) return const [];
    return List.unmodifiable(
      store.trackedCandidates.where((entry) => entry.$1 == _user.id).map((
        entry,
      ) {
        final latest =
            store.assessmentAttempts
                .where(
                  (attempt) =>
                      attempt.candidateId == entry.$2.candidateId &&
                      attempt.status == AssessmentStatus.completed,
                )
                .toList()
              ..sort(
                (a, b) => (b.completedAt ?? b.startedAt).compareTo(
                  a.completedAt ?? a.startedAt,
                ),
              );
        if (latest.isEmpty) return entry.$2;
        final attempt = latest.first;
        return TrackedCandidate(
          candidateId: entry.$2.candidateId,
          name: entry.$2.name,
          headline: entry.$2.headline,
          followedAt: entry.$2.followedAt,
          latestScorePercent: attempt.scorePercent,
          latestAssessmentAt: attempt.completedAt,
        );
      }),
    );
  }

  @override
  Future<List<AssessmentAssignment>> assignments() async => List.unmodifiable(
    store.assessmentAssignments.where(
      (item) => _isRecruiter
          ? item.recruiterId == _user.id
          : item.candidateId == auth.profileId,
    ),
  );

  @override
  Future<TrackedCandidate> follow(EntityId candidateId) async {
    _requireRecruiter();
    final existing = store.trackedCandidates
        .where(
          (entry) =>
              entry.$1 == _user.id && entry.$2.candidateId == candidateId,
        )
        .firstOrNull;
    if (existing != null) return existing.$2;
    final candidate = store.candidates
        .where((item) => item.id == candidateId)
        .firstOrNull;
    if (candidate == null) {
      throw const AppFailure(FailureKind.notFound, 'candidate_not_found');
    }
    final tracked = TrackedCandidate(
      candidateId: candidate.id,
      name: candidate.name,
      headline: candidate.headline,
      followedAt: DateTime.now().toUtc(),
    );
    store.trackedCandidates.add((_user.id, tracked));
    return tracked;
  }

  @override
  Future<void> unfollow(EntityId candidateId) async {
    _requireRecruiter();
    store.trackedCandidates.removeWhere(
      (entry) => entry.$1 == _user.id && entry.$2.candidateId == candidateId,
    );
  }

  @override
  Future<AssessmentAssignment> assign({
    required EntityId candidateId,
    required String disciplineCode,
    required String targetGrade,
  }) async {
    _requireRecruiter();
    final candidate = store.candidates
        .where((item) => item.id == candidateId)
        .firstOrNull;
    if (candidate == null) {
      throw const AppFailure(FailureKind.notFound, 'candidate_not_found');
    }
    final tests = await assessments.catalog();
    if (!tests.any(
      (test) => test.discipline == disciplineCode && test.grade == targetGrade,
    )) {
      throw const AppFailure(FailureKind.notFound, 'assessment_not_found');
    }
    final assignment = AssessmentAssignment(
      id: store.nextId(),
      recruiterId: _user.id,
      candidateId: candidate.id,
      candidateName: candidate.name,
      disciplineCode: disciplineCode,
      targetGrade: targetGrade,
      status: AssessmentAssignmentStatus.assigned,
      assignedAt: DateTime.now().toUtc(),
    );
    store.assessmentAssignments.add(assignment);
    return assignment;
  }

  @override
  Future<AssessmentAttempt> startAssignment(EntityId assignmentId) async {
    final assignment = store.assessmentAssignments
        .where(
          (item) =>
              item.id == assignmentId &&
              item.candidateId == auth.profileId &&
              item.status == AssessmentAssignmentStatus.assigned,
        )
        .firstOrNull;
    if (assignment == null) {
      throw const AppFailure(
        FailureKind.notFound,
        'assessment_assignment_not_found',
      );
    }
    final attempt = await assessments.start(
      assignment.testId,
      assignmentId: assignment.id.value,
    );
    _replace(
      assignment.copyWith(
        status: AssessmentAssignmentStatus.inProgress,
        attemptId: attempt.id,
      ),
    );
    return attempt;
  }

  void _requireRecruiter() {
    if (!_isRecruiter) {
      throw const AppFailure(FailureKind.forbidden, 'forbidden');
    }
  }

  void _replace(AssessmentAssignment assignment) {
    final index = store.assessmentAssignments.indexWhere(
      (item) => item.id == assignment.id,
    );
    store.assessmentAssignments[index] = assignment;
  }
}
