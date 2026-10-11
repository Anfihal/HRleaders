import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/core/routing/destinations.dart';
import 'package:hrleaders/features/admin/application/admin_use_cases.dart';
import 'package:hrleaders/features/admin/data/unsupported_admin_repository.dart';
import 'package:hrleaders/features/auth/domain/auth.dart';

void main() {
  late AppDependencies deps;
  setUp(() => deps = AppDependencies.demo());
  tearDown(() => deps.dispose());
  Future<void> login(Role role) => deps.auth.login(
    Email('${role.name}@demo.hrleaders.example'),
    'Demo12345',
  );
  final forbidden = throwsA(
    isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.forbidden),
  );
  test('analysts can read promotion metrics but cannot moderate users or vacancies', () async {
    await login(Role.analyst);
    expect((await GetAdminDashboard(deps.admin, deps.access)()).candidates, 45);
    await expectLater(() => GetUsers(deps.admin, deps.access)(), forbidden);
    await expectLater(
      () => GetModeratedVacancies(deps.admin, deps.access)(),
      forbidden,
    );
    expect(
      destinationsFor(deps.auth.current!.user).first,
      Destination.adminHome,
    );
  });
  test(
    'moderation updates shared vacancies, blocks login and records an audit',
    () async {
      await login(Role.admin);
      final vacancy = (await GetModeratedVacancies(
        deps.admin,
        deps.access,
      )()).first;
      await ModerateVacancy(deps.admin, deps.access)(vacancy.id);
      expect((await deps.admin.vacancies()).first.isOpen, isFalse);
      final hr = (await GetUsers(
        deps.admin,
        deps.access,
      )()).firstWhere((u) => u.user.role == Role.hr);
      await BlockUser(deps.admin, deps.access)(hr.user.id, true);
      expect(
        (await GetAuditLog(deps.admin, deps.access)()).map((e) => e.action),
        ['block', 'closeVacancy'],
      );
      await expectLater(
        () => deps.auth.login(hr.user.email, 'Demo12345'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unauthenticated,
          ),
        ),
      );
      await BlockUser(deps.admin, deps.access)(hr.user.id, false);
      await login(Role.hr);
      expect((await deps.hiring.vacancies()).first.isOpen, isFalse);
    },
  );
  test(
    'unimplemented live moderation returns a typed unsupported failure',
    () async {
      final repository = UnsupportedAdminRepository();
      final unsupported = throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unsupported,
        ),
      );
      await expectLater(repository.vacancies(), unsupported);
      await expectLater(
        repository.moderateVacancy(
          EntityId('00000000-0000-4000-8000-000000000400'),
        ),
        unsupported,
      );
    },
  );
}
