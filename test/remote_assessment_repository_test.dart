import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/demo_store.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/network/api_client.dart';
import 'package:hrleaders/features/assessments/data/remote_assessment_repository.dart';
import 'package:hrleaders/features/auth/data/mock_auth_repository.dart';

void main() {
  test('submitted attempt without a score is represented as pending', () async {
    final auth = MockAuthRepository(DemoStore());
    await auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
    final repository = RemoteAssessmentRepository(_AssessmentApi(), auth);

    final catalog = await repository.catalog();
    expect(catalog, hasLength(1));
    final report = await repository.report(
      EntityId('00000000-0000-0000-0000-000000000001'),
    );

    expect(report.awaitingScore, isTrue);
    expect(report.percent, isNull);
    expect(report.correctAnswers, isNull);
    expect(report.attempt.completedAt, isNull);
    expect(report.attempt.answers, [null]);
    expect(repository.supportsReflection, isFalse);
  });
}

final class _AssessmentApi implements ApiClient {
  @override
  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    if (method == 'GET' && path == 'assessments/questions') {
      return [
        {
          'id': 'question-1',
          'discipline_code': 'algorithmic',
          'target_grade': 'junior',
          'difficulty': 1,
          'question_type': 'single_choice',
          'body': 'Select an option.',
          'options': ['A', 'B'],
          'skills': ['Reasoning'],
          'points': 1,
        },
      ];
    }
    if (method == 'GET' &&
        path == 'assessments/attempts/00000000-0000-0000-0000-000000000001') {
      return {
        'id': '00000000-0000-0000-0000-000000000001',
        'discipline_code': 'algorithmic',
        'target_grade': 'junior',
        'status': 'submitted',
        'question_ids': ['question-1'],
        'started_at': '2026-01-01T10:00:00Z',
        'submitted_at': null,
        'scored_at': null,
        'score': null,
        'max_score': null,
        'score_percent': null,
        'passed': null,
        'time_spent_seconds': null,
        'answers': [
          {
            'id': 'answer-1',
            'question_id': 'question-1',
            'answer': 'unknown option',
            'is_correct': null,
            'points_earned': null,
          },
        ],
      };
    }
    throw StateError('Unexpected API request: $method $path');
  }
}
