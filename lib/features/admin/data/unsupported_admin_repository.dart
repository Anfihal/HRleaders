import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../domain/admin.dart';
import '../../hiring/domain/hiring.dart';

final class UnsupportedAdminRepository implements AdminRepository {
  @override
  Future<List<Vacancy>> vacancies() async => _unsupported();
  @override
  Future<void> moderateVacancy(EntityId id) async => _unsupported();
  Never _unsupported() => throw const AppFailure(
    FailureKind.unsupported,
    'admin_contract_unavailable',
  );
  @override
  Future<AdminSnapshot> dashboard() async => _unsupported();
  @override
  Future<List<AdminUser>> users() async => _unsupported();
  @override
  Future<void> setBlocked(EntityId id, bool blocked) async => _unsupported();
  @override
  Future<GatewaySnapshot> gateway() async => _unsupported();
  @override
  Future<List<AuditEvent>> audit() async => _unsupported();
}
