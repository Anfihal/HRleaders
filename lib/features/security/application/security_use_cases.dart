import '../../../core/error/app_failure.dart';
import '../../auth/domain/auth.dart';
import '../domain/security.dart';

final class GetSecurityOverview {
  const GetSecurityOverview(this.repository, this.auth);
  final SecurityRepository repository;
  final AuthRepository auth;
  Future<SecuritySnapshot> call() {
    if (auth.current == null) {
      throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated');
    }
    return repository.overview();
  }
}

final class GetNotifications {
  const GetNotifications(this.repository, this.auth);
  final SecurityRepository repository;
  final AuthRepository auth;
  Future<List<AppNotification>> call() {
    if (auth.current == null) {
      throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated');
    }
    return repository.notifications();
  }
}

final class MarkNotificationRead {
  const MarkNotificationRead(this.repository, this.auth);
  final SecurityRepository repository;
  final AuthRepository auth;
  Future<void> call(String id) {
    if (auth.current == null) {
      throw const AppFailure(FailureKind.unauthenticated, 'unauthenticated');
    }
    return repository.markRead(id);
  }
}
