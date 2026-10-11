import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/network/api_client.dart';
import 'package:hrleaders/features/auth/data/mock_auth_repository.dart';
import 'package:hrleaders/features/recruiter_cjm/data/remote_recruiter_cjm_repository.dart';
import 'package:hrleaders/features/recruiter_cjm/domain/recruiter_cjm.dart';

void main() {
  test('remote tracking and assignment map the OpenAPI contract', () async {
    final dependencies = AppDependencies.demo();
    addTearDown(dependencies.dispose);
    final auth = dependencies.auth as MockAuthRepository;
    await auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
    final api = _RecruiterCjmApi();
    final repository = RemoteRecruiterCjmRepository(
      api,
      auth,
      dependencies.assessments,
    );

    final followed = await repository.followedCandidates();
    expect(followed.single.candidateId.value, _candidateId);
    expect(followed.single.latestScorePercent, 88.5);

    final assignments = await repository.assignments();
    expect(assignments.single.status, AssessmentAssignmentStatus.assigned);
    expect(assignments.single.testId, 'algorithmic::junior');

    await repository.follow(EntityId(_candidateId));
    await repository.unfollow(EntityId(_candidateId));
    final created = await repository.assign(
      candidateId: EntityId(_candidateId),
      disciplineCode: 'algorithmic',
      targetGrade: 'junior',
    );
    expect(created.status, AssessmentAssignmentStatus.assigned);
    expect(api.lastBody, {
      'candidate_id': _candidateId,
      'discipline_code': 'algorithmic',
      'target_grade': 'junior',
    });
    expect(
      api.requests.map((request) => '${request.$1} ${request.$2}'),
      containsAll([
        'GET recruiting/tracked-candidates',
        'GET recruiting/assessment-assignments',
        'PUT recruiting/tracked-candidates/$_candidateId',
        'DELETE recruiting/tracked-candidates/$_candidateId',
        'POST recruiting/assessment-assignments',
      ]),
    );
  });
}

const _candidateId = '00000000-0000-4000-8000-000000000200';
const _recruiterId = '00000000-0000-4000-8000-000000000101';
const _assignmentId = '00000000-0000-4000-8000-000000000701';

final class _RecruiterCjmApi implements ApiClient {
  final List<(String, String)> requests = [];
  Map<String, Object?>? lastBody;

  Map<String, Object?> get tracked => {
    'candidate_id': _candidateId,
    'candidate_name': 'Daria Orlova',
    'headline': 'Flutter engineer',
    'followed_at': '2026-01-01T10:00:00Z',
    'latest_score_percent': 88.5,
    'latest_assessment_at': '2026-01-03T10:00:00Z',
  };

  Map<String, Object?> get assignment => {
    'id': _assignmentId,
    'recruiter_id': _recruiterId,
    'candidate_id': _candidateId,
    'candidate_name': 'Daria Orlova',
    'discipline_code': 'algorithmic',
    'target_grade': 'junior',
    'status': 'assigned',
    'assigned_at': '2026-01-02T10:00:00Z',
    'due_at': null,
    'attempt_id': null,
    'score_percent': null,
  };

  @override
  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    requests.add((method, path));
    lastBody = body;
    if (method == 'GET' && path == 'recruiting/tracked-candidates') {
      return [tracked];
    }
    if (method == 'GET' && path == 'recruiting/assessment-assignments') {
      return [assignment];
    }
    if (method == 'PUT' &&
        path == 'recruiting/tracked-candidates/$_candidateId') {
      return tracked;
    }
    if (method == 'DELETE' &&
        path == 'recruiting/tracked-candidates/$_candidateId') {
      return null;
    }
    if (method == 'POST' && path == 'recruiting/assessment-assignments') {
      return assignment;
    }
    throw StateError('Unexpected request: $method $path');
  }
}
