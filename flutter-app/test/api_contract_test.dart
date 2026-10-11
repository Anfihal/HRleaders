import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hrleaders/core/models/api_models.dart';
import 'package:hrleaders/core/network/api_client.dart';
import 'package:hrleaders/core/network/api_v1_contract.dart';

void main() {
  test('models preserve extra fields and round-trip exact wire values', () {
    final funnel = ApiFunnelResponse.fromJson({
      'candidates_viewed': 1,
      'candidates_contacted': 2,
      'offers_sent': 3,
      'offers_opened': 4,
      'offers_accepted': 5,
      'offers_declined': 6,
      'offers_withdrawn': 7,
      'offers_awaiting': 8,
      'future_metric': {
        'segment': 'mobile',
        'value': 9,
      },
    });
    expect(funnel.toJson()['future_metric'], {
      'segment': 'mobile',
      'value': 9,
    });
    expect(ApiRole.employer.toJson(), 'employer');
    expect(ApiRole.fromJson('candidate'), ApiRole.candidate);

    final achievement = ApiFspAchievementResponse.fromJson({
      'competition_name': 'Final',
      'held_on': '2025-03-02',
      'discipline_code': 'algorithmic',
      'competition_level_code': 'national',
      'result_code': 'first',
    });
    expect(achievement.toJson()['held_on'], '2025-03-02');
  });

  test('nullable missing fields stay null and required fields are validated', () {
    expect(ApiHTTPValidationError.fromJson({}).detail, isNull);
    expect(
      () => ApiFunnelResponse.fromJson({'candidates_viewed': 1}),
      throwsFormatException,
    );
    expect(() => ApiRole.fromJson('future-role'), throwsFormatException);
  });

  test('operation metadata covers the spec and validates path/query/body', () {
    expect(apiV1Operations, hasLength(64));
    final gradeOperation =
        apiV1Operations['resolve_grade_api_v1_assessments_attempts__attempt_id__resolve_grade_post']!;
    expect(
      gradeOperation.resolvePath({
        'attempt_id': '00000000-0000-4000-8000-000000000001',
      }),
      'assessments/attempts/00000000-0000-4000-8000-000000000001/resolve-grade',
    );
    expect(
      () => gradeOperation.resolvePath({'attempt_id': 'not-a-uuid'}),
      throwsArgumentError,
    );
    expect(
      () => gradeOperation.validate(
        pathParameters: {
          'attempt_id': '00000000-0000-4000-8000-000000000001',
        },
        query: {},
        body: null,
      ),
      throwsArgumentError,
    );
    expect(
      () => gradeOperation.validate(
        pathParameters: {
          'attempt_id': '00000000-0000-4000-8000-000000000001',
        },
        query: {'unknown': 'value'},
        body: null,
      ),
      throwsArgumentError,
    );
    final searchOperation =
        apiV1Operations['search_candidates_api_v1_candidates_get']!;
    expect(
      () => searchOperation.validate(
        pathParameters: {},
        query: {'limit': '0'},
        body: null,
      ),
      throwsArgumentError,
    );
    final commandOperation =
        apiV1Operations['connection_command_api_v1_recruiting_interviews__entity_id__session__action__post']!;
    expect(
      commandOperation.resolvePath({
        'entity_id': '00000000-0000-4000-8000-000000000001',
        'action': 'pause/action',
      }),
      'recruiting/interviews/00000000-0000-4000-8000-000000000001/session/pause%2Faction',
    );
    expect(
      () => apiV1Operations['login_api_v1_auth_login_post']!.validate(
        pathParameters: {},
        query: {},
        body: ApiFunnelResponse(
          candidatesViewed: 0,
          candidatesContacted: 0,
          offersSent: 0,
          offersOpened: 0,
          offersAccepted: 0,
          offersDeclined: 0,
          offersWithdrawn: 0,
          offersAwaiting: 0,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('contract client sends a typed request and accepts a 204 response', () async {
    final seen = <http.Request>[];
    final httpClient = MockClient((request) async {
      seen.add(request);
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response('{"user":{"id":"example"}}', 200);
      }
      return http.Response('', 204);
    });
    final api = HttpApiClient(
      baseUri: Uri.parse('https://hrleaders.example/api/v1/'),
      client: httpClient,
      token: () => null,
    );
    final contract = ApiV1Client(api);

    final login = await contract.execute<Map<String, Object?>>(
      'login_api_v1_auth_login_post',
      body: ApiLoginRequest(email: 'user@example.com', password: 'secret'),
      decode: (value) => value! as Map<String, Object?>,
    );
    expect(login['user'], {'id': 'example'});
    expect(jsonDecode(seen.first.body), {
      'email': 'user@example.com',
      'password': 'secret',
    });

    await contract.executeNoContent('logout_api_v1_auth_logout_post');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/api/v1/auth/logout');
    expect(seen.last.body, isEmpty);
    api.close();
  });
}
