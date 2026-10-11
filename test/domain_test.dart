import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/features/auth/domain/auth.dart';
import 'package:hrleaders/features/hiring/domain/hiring.dart';

void main() {
  test('email normalizes and invalid email/salary/range are rejected', () {
    expect(Email(' HR@Example.org ').value, 'hr@example.org');
    expect(() => Email('broken'), throwsA(isA<AppFailure>()));
    expect(() => Salary(0), throwsA(isA<AppFailure>()));
    expect(() => SalaryRange(300000, 200000), throwsA(isA<AppFailure>()));
    expect(SalaryRange(200000, 300000).contains(Salary(250000)), isTrue);
    expect(SalaryRange(200000, 300000).contains(Salary(350000)), isFalse);
  });

  test('permission matrix isolates candidate, HR and administration', () {
    expect(Role.candidate.permissions, contains(Permission.respondOffers));
    expect(
      Role.candidate.permissions,
      isNot(contains(Permission.viewCandidates)),
    );
    expect(Role.hr.permissions, contains(Permission.sendOffers));
    expect(Role.hr.permissions, isNot(contains(Permission.manageUsers)));
    expect(Role.analyst.permissions, contains(Permission.viewAnalytics));
    expect(Role.analyst.permissions, isNot(contains(Permission.manageUsers)));
    expect(Role.superadmin.permissions, containsAll(Permission.values));
  });

  test('a match requires an accepted offer', () {
    final vacancy = Vacancy(
      id: EntityId('00000000-0000-4000-8000-000000000010'),
      title: 'Dart engineer',
      salary: SalaryRange(200000, 300000),
      isOpen: true,
      createdAt: DateTime.utc(2026),
    );
    Offer offer(OfferStatus status) => Offer(
      id: EntityId('00000000-0000-4000-8000-000000000020'),
      candidateId: EntityId('00000000-0000-4000-8000-000000000030'),
      candidateName: 'Candidate',
      companyName: 'Company',
      vacancy: vacancy,
      salary: Salary(250000),
      message: 'A concrete offer',
      status: status,
      createdAt: DateTime.utc(2026),
    );
    expect(
      () => Match.fromOffer(offer(OfferStatus.sent)),
      throwsA(isA<AppFailure>()),
    );
    expect(
      Match.fromOffer(offer(OfferStatus.accepted)).offer.salary.amount,
      250000,
    );
  });
}
