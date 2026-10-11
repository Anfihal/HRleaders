import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/features/auth/application/auth_use_cases.dart';
import 'package:hrleaders/features/auth/domain/auth.dart';
import 'package:hrleaders/features/candidates/application/candidate_use_cases.dart';
import 'package:hrleaders/features/candidates/domain/candidates.dart';
import 'package:hrleaders/features/hiring/application/hiring_use_cases.dart';
import 'package:hrleaders/features/hiring/domain/hiring.dart';

Matcher fails(FailureKind kind) =>
    throwsA(isA<AppFailure>().having((e) => e.kind, 'kind', kind));
void main() {
  late AppDependencies deps;
  setUp(() => deps = AppDependencies.demo());
  tearDown(() => deps.dispose());
  Future<void> login(Role role) async {
    await AuthenticateUser(deps.auth)(
      '${role.name}@demo.hrleaders.example',
      'Demo12345',
    );
  }

  test(
    'a registered demo account can sign out and sign in with its password',
    () async {
      final registration = Registration(
        email: Email('new@example.com'),
        password: 'Chosen12345',
        name: 'New specialist',
        role: Role.candidate,
      );
      await RegisterUser(deps.auth)(registration);
      await deps.auth.logout();
      final session = await AuthenticateUser(deps.auth)(
        'new@example.com',
        'Chosen12345',
      );
      expect(session.user.name, 'New specialist');
      await deps.auth.logout();
      await expectLater(
        () => AuthenticateUser(deps.auth)('new@example.com', 'Demo12345'),
        fails(FailureKind.unauthenticated),
      );
    },
  );
  test('profile verification, HR search, concrete offer and acceptance form a shared match', () async {
    await login(Role.candidate);
    final profile = await GetCandidateProfile(deps.candidates, deps.access)();
    expect(
      (await VerifyCandidateByFsp(deps.candidates, deps.access)()).verified,
      isTrue,
    );
    await login(Role.hr);
    final page = await SearchCandidates(deps.candidates, deps.access)(
      const CandidateFilter(skill: 'Flutter', verifiedOnly: true),
      offset: 0,
      limit: 5,
    );
    expect(page.items, isNotEmpty);
    expect(page.hasMore, isTrue);
    expect(
      page.items.every((c) => c.verified && c.skills.contains('Flutter')),
      isTrue,
    );
    final vacancy = await CreateVacancy(deps.hiring, deps.access)(
      VacancyDraft(
        title: 'Mobile engineer',
        salary: SalaryRange(200000, 300000),
        description: 'Build accessible mobile products.',
      ),
    );
    final offer = await SendOffer(deps.hiring, deps.access)(
      OfferDraft(
        vacancy: vacancy,
        candidateId: profile.id,
        salary: Salary(250000),
        message: 'Your achievements are a great fit for our team.',
      ),
    );
    await expectLater(
      () => SendOffer(deps.hiring, deps.access)(
        OfferDraft(
          vacancy: vacancy,
          candidateId: profile.id,
          salary: Salary(250000),
          message: 'Duplicate invitation to the same vacancy.',
        ),
      ),
      fails(FailureKind.conflict),
    );
    await login(Role.candidate);
    expect(
      (await GetMatches(GetOffers(deps.hiring, deps.access))(incoming: true)),
      isEmpty,
    );
    await RespondToOffer(deps.hiring, deps.access)(
      offer.id,
      OfferStatus.viewed,
    );
    await RespondToOffer(deps.hiring, deps.access)(
      offer.id,
      OfferStatus.accepted,
    );
    final matches = await GetMatches(GetOffers(deps.hiring, deps.access))(
      incoming: true,
    );
    expect(matches.single.offer.id, offer.id);
    await expectLater(
      () => RespondToOffer(deps.hiring, deps.access)(
        offer.id,
        OfferStatus.declined,
        reason: 'Changed my mind',
      ),
      fails(FailureKind.conflict),
    );
    await login(Role.hr);
    expect(
      (await GetMatches(GetOffers(deps.hiring, deps.access))(incoming: false))
          .single
          .offer
          .id,
      offer.id,
    );
    expect((await deps.analytics.overview()).accepted, 1);
  });
  test('decline requires a reason; withdrawn and declined offers never become matches', () async {
    await login(Role.candidate);
    final offers = await GetOffers(deps.hiring, deps.access)(incoming: true);
    await expectLater(
      () => RespondToOffer(deps.hiring, deps.access)(
        offers.first.id,
        OfferStatus.declined,
        reason: ' ',
      ),
      fails(FailureKind.validation),
    );
    await RespondToOffer(deps.hiring, deps.access)(
      offers.first.id,
      OfferStatus.declined,
      reason: 'Seeking another work format',
    );
    expect(
      await GetMatches(GetOffers(deps.hiring, deps.access))(incoming: true),
      isEmpty,
    );
    await login(Role.hr);
    final vacancy = (await GetVacancies(deps.hiring, deps.access)()).first;
    final second = await SendOffer(deps.hiring, deps.access)(
      OfferDraft(
        vacancy: vacancy,
        candidateId: offers.first.candidateId,
        salary: Salary(250000),
        message: 'Another role for your consideration.',
      ),
    );
    await RespondToOffer(deps.hiring, deps.access)(
      second.id,
      OfferStatus.withdrawn,
    );
    expect(
      await GetMatches(GetOffers(deps.hiring, deps.access))(incoming: false),
      isEmpty,
    );
  });
  test('commands enforce roles before touching repositories', () async {
    await expectLater(
      () => SearchCandidates(deps.candidates, deps.access)(
        const CandidateFilter(),
        offset: 0,
        limit: 20,
      ),
      fails(FailureKind.unauthenticated),
    );
    await login(Role.candidate);
    await expectLater(
      () => GetVacancies(deps.hiring, deps.access)(),
      fails(FailureKind.forbidden),
    );
    await login(Role.hr);
    await expectLater(
      () => GetCandidateProfile(deps.candidates, deps.access)(),
      fails(FailureKind.forbidden),
    );
    await expectLater(
      () => SearchCandidates(deps.candidates, deps.access)(
        const CandidateFilter(),
        offset: -1,
        limit: 20,
      ),
      fails(FailureKind.validation),
    );
  });
  test('closed vacancies reject stale send forms', () async {
    await login(Role.hr);
    final vacancy = (await GetVacancies(deps.hiring, deps.access)()).first;
    final candidate = (await SearchCandidates(deps.candidates, deps.access)(
      const CandidateFilter(),
      offset: 0,
      limit: 20,
    )).items[1];
    await CloseVacancy(deps.hiring, deps.access)(vacancy.id);
    await expectLater(
      () => SendOffer(deps.hiring, deps.access)(
        OfferDraft(
          vacancy: vacancy,
          candidateId: candidate.id,
          salary: Salary(240000),
          message: 'A stale form submitted after the vacancy closes.',
        ),
      ),
      fails(FailureKind.conflict),
    );
  });
}
