import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/domain/auth.dart';
import '../../hiring/domain/hiring.dart';
import '../domain/admin.dart';

final class MockAdminRepository implements AdminRepository {
  const MockAdminRepository(this.store, this.auth);
  final DemoStore store;
  final AuthRepository auth;
  @override
  Future<List<Vacancy>> vacancies() async => List.unmodifiable(store.vacancies);
  @override
  Future<void> moderateVacancy(EntityId id) async {
    final old = store.vacancies.where((v) => v.id == id).firstOrNull;
    if (old == null) {
      throw const AppFailure(FailureKind.notFound, 'vacancy_not_found');
    }
    store.vacancies[store.vacancies.indexOf(old)] = Vacancy(
      id: old.id,
      title: old.title,
      salary: old.salary,
      isOpen: false,
      createdAt: old.createdAt,
      discipline: old.discipline,
      grade: old.grade,
      workFormat: old.workFormat,
      skills: old.skills,
      description: old.description,
    );
    store.audit.insert(
      0,
      AuditEvent(
        store.nextId().value,
        DateTime.now().toUtc(),
        auth.current!.user.id,
        'closeVacancy',
      ),
    );
  }

  @override
  Future<AdminSnapshot> dashboard() async => AdminSnapshot(
    users: store.users.length,
    candidates: store.candidates.length,
    hr: store.users.where((u) => u.user.role == Role.hr).length,
    vacancies: store.vacancies.where((v) => v.isOpen).length,
    matches: store.offers.where((o) => o.status == OfferStatus.accepted).length,
    verificationRate:
        store.candidates.where((c) => c.verified).length /
        store.candidates.length,
    averageMatchHours: 24,
    regions: const [
      RegionMetric(RegionCode.moscow, 18),
      RegionMetric(RegionCode.petersburg, 8),
      RegionMetric(RegionCode.kazan, 11),
      RegionMetric(RegionCode.novosibirsk, 8),
    ],
  );
  @override
  Future<List<AdminUser>> users() async => List.unmodifiable(store.users);
  @override
  Future<void> setBlocked(EntityId id, bool blocked) async {
    if (auth.current!.user.id == id) {
      throw const AppFailure(FailureKind.conflict, 'cannot_block_self');
    }
    final index = store.users.indexWhere((entry) => entry.user.id == id);
    if (index < 0) {
      throw const AppFailure(FailureKind.notFound, 'user_not_found');
    }
    store.users[index] = AdminUser(store.users[index].user, blocked: blocked);
    store.audit.insert(
      0,
      AuditEvent(
        store.nextId().value,
        DateTime.now().toUtc(),
        auth.current!.user.id,
        blocked ? 'block' : 'unblock',
      ),
    );
  }

  @override
  Future<GatewaySnapshot> gateway() async => GatewaySnapshot(
    status: GatewayStatus.online,
    lastSync: DateTime.utc(2026, 10, 1),
    queue: 3,
    errors: 0,
    requests: 64,
    latencyMs: 82,
  );
  @override
  Future<List<AuditEvent>> audit() async => List.unmodifiable(store.audit);
}
