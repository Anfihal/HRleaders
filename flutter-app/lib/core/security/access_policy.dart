import '../../features/auth/domain/auth.dart';
import '../error/app_failure.dart';

final class AccessPolicy {
  const AccessPolicy(this.auth);
  final AuthRepository auth;
  User require(Permission permission) {
    final user = auth.current?.user;
    if (user == null) {
      throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated');
    }
    if (!user.can(permission)) {
      throw const AppFailure(FailureKind.forbidden, 'forbidden');
    }
    return user;
  }
}
