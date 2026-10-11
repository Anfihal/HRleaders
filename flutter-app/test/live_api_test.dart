import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/security/access_policy.dart';
import 'package:hrleaders/core/security/token_storage.dart';
import 'package:hrleaders/core/network/api_client.dart';
import 'package:hrleaders/features/auth/data/auth_repository.dart';
import 'package:hrleaders/features/auth/application/auth_use_cases.dart';
import 'package:hrleaders/features/auth/domain/auth.dart';
import 'package:hrleaders/features/candidates/data/candidate_repository.dart';
import 'package:hrleaders/features/candidates/application/candidate_use_cases.dart';
import 'package:hrleaders/features/candidates/domain/candidates.dart';
import 'package:hrleaders/features/hiring/data/hiring_repository.dart';
import 'package:hrleaders/features/hiring/application/hiring_use_cases.dart';
import 'package:hrleaders/features/hiring/domain/hiring.dart';
import 'package:hrleaders/features/analytics/data/analytics_repository.dart';

import 'network_test.dart' show MemoryTokens;

void main() {
  const url = String.fromEnvironment('TEST_API_URL');
  test(
    'Flutter adapters complete reverse hiring against real FastAPI and FSP gateway',
    () async {
      final token = TokenHolder();
      final api = HttpApiClient(
        baseUri: Uri.parse(url),
        client: http.Client(),
        token: () => token.value,
      );
      addTearDown(api.close);
      final auth = RemoteAuthRepository(
        AuthApiDataSource(api),
        MemoryTokens(),
        token,
        cookieSession: false,
      );
      final access = AccessPolicy(auth);
      final candidates = RemoteCandidateRepository(CandidateApiDataSource(api));
      final hiring = RemoteHiringRepository(HiringApiDataSource(api));
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final email = 'flutter-candidate-$suffix@example.com',
          hrEmail = 'flutter-hr-$suffix@example.com';
      await RegisterUser(auth)(
        Registration(
          email: Email(email),
          password: 'Test12345',
          name: 'Иванов Артём Сергеевич',
          role: Role.candidate,
        ),
      );
      final saved = await UpdateCandidateProfile(candidates, access)(
        ProfileDraft(
          name: 'Иванов Артём Сергеевич',
          headline: 'Flutter contract engineer',
          city: 'Москва',
          grade: Grade.senior,
          workFormat: WorkFormat.remote,
          skills: ['Flutter-contract'],
          salary: Salary(240000),
          fspId: 'FSP-1001',
        ),
      );
      final verified = await VerifyCandidateByFsp(candidates, access)();
      expect(verified.verified, isTrue);
      expect(verified.achievements, isNotEmpty);
      await auth.logout();
      await RegisterUser(auth)(
        Registration(
          email: Email(hrEmail),
          password: 'Test12345',
          name: 'HR reviewer',
          role: Role.hr,
          company: 'Contract test company',
        ),
      );
      expect(
        (await GetDictionaries(candidates)()).options('disciplines'),
        isNotEmpty,
      );
      final search = await SearchCandidates(candidates, access)(
        const CandidateFilter(skill: 'Flutter-contract', verifiedOnly: true),
      );
      expect(search.items.map((c) => c.id), contains(saved.id));
      expect(
        (await GetCandidateDetails(candidates, access)(saved.id)).achievements,
        isNotEmpty,
      );
      final vacancy = await CreateVacancy(hiring, access)(
        VacancyDraft(
          title: 'Flutter contract engineer',
          salary: SalaryRange(200000, 300000),
          skills: ['Flutter-contract'],
          description: 'Build a reliable integration.',
        ),
      );
      final sent = await SendOffer(hiring, access)(
        OfferDraft(
          vacancy: vacancy,
          candidateId: saved.id,
          salary: Salary(250000),
          message: 'Your verified achievements fit our engineering role.',
        ),
      );
      expect(sent.status, OfferStatus.sent);
      await auth.logout();
      await AuthenticateUser(auth)(email, 'Test12345');
      expect(
        (await GetOffers(hiring, access)(incoming: true)).single.id,
        sent.id,
      );
      await RespondToOffer(hiring, access)(sent.id, OfferStatus.viewed);
      await RespondToOffer(hiring, access)(sent.id, OfferStatus.accepted);
      expect(
        (await GetMatches(GetOffers(hiring, access))(incoming: true))
            .single
            .offer
            .id,
        sent.id,
      );
      await auth.logout();
      await AuthenticateUser(auth)(hrEmail, 'Test12345');
      expect(
        (await GetMatches(GetOffers(hiring, access))(incoming: false))
            .single
            .offer
            .id,
        sent.id,
      );
      final analytics = await RemoteAnalyticsRepository(api).overview();
      expect(analytics.accepted, 1);
      expect(analytics.sent, 1);
      expect(analytics.views, 1);
      await CloseVacancy(hiring, access)(vacancy.id);
      expect((await GetVacancies(hiring, access)()).single.isOpen, isFalse);
      await auth.logout();
      expect(token.value, isNull);
    },
    skip: url.isEmpty
        ? 'Run examples/test-flutter-api.sh for the live contract test'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
