import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/core/network/api_client.dart';
import 'package:hrleaders/core/security/token_storage.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/features/auth/data/auth_repository.dart';
import 'package:hrleaders/features/candidates/data/candidate_repository.dart';
import 'package:hrleaders/features/candidates/domain/candidates.dart';
import 'package:hrleaders/features/hiring/data/hiring_repository.dart';
import 'package:hrleaders/features/hiring/domain/hiring.dart';

final userJson = {
  'id': '00000000-0000-4000-8000-000000000100',
  'email': 'candidate@example.com',
  'full_name': 'Specialist',
  'role': 'candidate',
  'company_name': null,
};
final candidateJson = {
  'id': userJson['id'],
  'full_name': 'Specialist',
  'headline': 'Flutter engineer',
  'city': null,
  'grade': 'middle',
  'team_role': null,
  'work_format': 'remote',
  'salary_expectation': 250000,
  'skills': ['Flutter'],
  'is_fsp_verified': true,
  'categories': [
    {
      'discipline_code': 'algorithmic',
      'score': 160,
      'level': {'code': 'confirmed', 'label': 'Подтверждённый'},
      'points_to_next_level': 40,
    },
  ],
};
final vacancyJson = {
  'id': '00000000-0000-4000-8000-000000000400',
  'title': 'Engineer',
  'salary_from': 200000,
  'salary_to': 300000,
  'description': 'Build products',
  'skills': ['Flutter'],
  'is_open': true,
  'created_at': '2026-10-01T12:00:00Z',
};
final offerJson = {
  'id': '00000000-0000-4000-8000-000000000500',
  'candidate_id': userJson['id'],
  'candidate_name': 'Specialist',
  'company_name': 'Company',
  'vacancy': vacancyJson,
  'salary': 250000,
  'message': 'Personal invitation',
  'status': 'accepted',
  'created_at': '2026-10-01T12:00:00Z',
  'responded_at': '2026-10-02T12:00:00Z',
};

final class MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  HttpApiClient api(
    http.Client client, {
    void Function()? unauthorized,
    void Function(String)? trace,
    Duration? timeout,
  }) => HttpApiClient(
    baseUri: Uri.parse('https://hrleaders.example/api/v1/'),
    client: client,
    token: () => 'private-token',
    onUnauthorized: unauthorized,
    trace: trace,
    requestTimeout: timeout ?? const Duration(seconds: 15),
  );
  test(
    'GET retries transient errors, mutations execute once, traces redact data',
    () async {
      var calls = 0;
      final traces = <String>[];
      final client = api(
        MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/v1/candidates');
          expect(request.headers['Authorization'], 'Bearer private-token');
          return http.Response(
            calls == 1 ? '{}' : '{"items":[]}',
            calls == 1 ? 503 : 200,
          );
        }),
        trace: traces.add,
      );
      expect(
        await client.request(
          'GET',
          'candidates',
          query: {'skill': 'private-profile'},
        ),
        {'items': []},
      );
      expect(calls, 2);
      expect(traces.join(), isNot(contains('private')));
      client.close();
      calls = 0;
      final mutation = api(
        MockClient((_) async {
          calls++;
          return http.Response('{}', 503);
        }),
      );
      await expectLater(
        mutation.request('POST', 'offers'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unavailable,
          ),
        ),
      );
      expect(calls, 1);
      mutation.close();
    },
  );
  test(
    'response body timeout is bounded, non-JSON failures remain typed',
    () async {
      final timed = api(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 5),
      );
      await expectLater(
        timed.request('POST', 'offers'),
        throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'timeout')),
      );
      timed.close();
      final invalid = api(
        MockClient((_) async => http.Response('<html>unavailable</html>', 502)),
      );
      await expectLater(
        invalid.request('GET', 'candidates'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unavailable,
          ),
        ),
      );
      invalid.close();
    },
  );
  test('401 expires sessions except incorrect sign-in credentials', () async {
    var expired = 0;
    final client = api(
      MockClient(
        (_) async => http.Response('{"error":{"code":"expired"}}', 401),
      ),
      unauthorized: () => expired++,
    );
    await expectLater(
      client.request('POST', 'auth/login'),
      throwsA(isA<AppFailure>()),
    );
    expect(expired, 0);
    await expectLater(
      client.request('GET', 'auth/me'),
      throwsA(isA<AppFailure>()),
    );
    expect(expired, 1);
    client.close();
  });
  test('FastAPI validation errors retain field messages and HTTP status', () async {
    final client = api(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'email'],
                'msg': 'value is not a valid email address',
                'type': 'value_error',
              },
              {
                'loc': ['body', 'items', 0, 'salary'],
                'msg': 'field required',
                'type': 'missing',
              },
            ],
          }),
          422,
        ),
      ),
    );
    await expectLater(
      client.request('POST', 'auth/login'),
      throwsA(
        isA<AppFailure>()
            .having((failure) => failure.kind, 'kind', FailureKind.validation)
            .having((failure) => failure.code, 'code', 'validation_error')
            .having((failure) => failure.statusCode, 'status', 422)
            .having(
              (failure) => failure.fields,
              'fields',
              {
                'email': 'value is not a valid email address',
                'items.0.salary': 'field required',
              },
            ),
      ),
    );
    client.close();
  });
  test(
    'native restores secure token and clears it on expiry and failed logout',
    () async {
      var status = 200;
      final tokens = MemoryTokens()..value = 'persisted';
      final holder = TokenHolder();
      final client = HttpApiClient(
        baseUri: Uri.parse('https://hrleaders.example/api/v1/'),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer persisted');
          return http.Response(jsonEncode(userJson), status);
        }),
        token: () => holder.value,
      );
      final auth = RemoteAuthRepository(
        AuthApiDataSource(client),
        tokens,
        holder,
        cookieSession: false,
      );
      expect((await auth.restore())?.user.name, 'Specialist');
      status = 503;
      await expectLater(auth.logout(), throwsA(isA<AppFailure>()));
      expect(auth.current, isNull);
      expect(tokens.value, isNull);
      expect(holder.value, isNull);
      client.close();
    },
  );
  test(
    'web never persists an access token and relies on cookie-authenticated me',
    () async {
      final tokens = MemoryTokens();
      final holder = TokenHolder();
      final client = HttpApiClient(
        baseUri: Uri.parse('https://hrleaders.example/api/v1/'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'user': userJson, 'access_token': 'must-not-persist'}),
            200,
          ),
        ),
        token: () => holder.value,
      );
      final auth = RemoteAuthRepository(
        AuthApiDataSource(client),
        tokens,
        holder,
        cookieSession: true,
      );
      await auth.login(Email('candidate@example.com'), 'Password123');
      expect(tokens.value, isNull);
      expect(holder.value, isNull);
      client.close();
    },
  );
  test('decoded dictionary lists remain typed and immutable', () async {
    final client = api(
      MockClient(
        (_) async => http.Response(
          '{"disciplines":[{"code":"algorithmic","label":"Programming"}]}',
          200,
        ),
      ),
    );
    final dictionaries = await CandidateApiDataSource(client).dictionaries();
    expect(dictionaries.options('disciplines').single.code, 'algorithmic');
    expect(
      () => dictionaries.options('disciplines').clear(),
      throwsUnsupportedError,
    );
    client.close();
  });
  test('summary DTO accepts absent detail fields, nested offers yield typed matches', () {
    final candidate = CandidateDto(candidateJson).toDomain();
    expect(candidate.grade, Grade.middle);
    expect(candidate.achievements, isEmpty);
    expect(candidate.categories.single.score, 160);
    expect(
      Match.fromOffer(OfferDto(offerJson).toDomain()).offer.salary.amount,
      250000,
    );
    expect(
      () => UserDto({...userJson, 'role': 'root'}).toDomain(),
      throwsA(
        isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.malformed),
      ),
    );
    expect(
      () => CandidateDto({...candidateJson, 'grade': 'unknown'}).toDomain(),
      throwsA(isA<AppFailure>()),
    );
  });
  test(
    'API data sources use the existing contracts and supported filters',
    () async {
      final requests = <http.Request>[];
      final client = api(
        MockClient((request) async {
          requests.add(request);
          final body = request.url.path.endsWith('fsp-sync')
              ? {'profile': candidateJson, 'imported': 1, 'skipped': []}
              : request.url.path.endsWith('/candidates')
              ? {
                  'items': [candidateJson],
                  'total': 1,
                  'offset': 0,
                  'limit': 20,
                }
              : offerJson;
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final candidates = CandidateApiDataSource(client);
      await candidates.search(
        CandidateFilter(
          skill: ' Flutter ',
          grade: Grade.middle,
          maxSalary: Salary(300000),
          verifiedOnly: true,
        ),
        0,
        20,
      );
      expect(requests.last.url.queryParameters['skill'], 'Flutter');
      expect(requests.last.url.queryParameters['verified_only'], 'true');
      await candidates.sync();
      expect(requests.last.method, 'POST');
      await HiringApiDataSource(client).respond(
        EntityId(offerJson['id']! as String),
        OfferStatus.declined,
        'Different format',
      );
      expect(requests.last.url.path, endsWith('/decline'));
      expect(jsonDecode(requests.last.body), {'reason': 'Different format'});
      client.close();
    },
  );
}
