import '../../../core/error/app_failure.dart';
import '../domain/security.dart';

final class UnsupportedSecurityRepository implements SecurityRepository {
  Never _unsupported() => throw const AppFailure(
    FailureKind.unsupported,
    'security_contract_unavailable',
  );
  @override
  Future<SecuritySnapshot> overview() async => _unsupported();
  @override
  Future<List<AppNotification>> notifications() async => _unsupported();
  @override
  Future<void> markRead(String id) async => _unsupported();
}
