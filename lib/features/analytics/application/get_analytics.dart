import '../../../core/security/access_policy.dart';
import '../../auth/domain/auth.dart';
import '../domain/analytics.dart';

final class GetAnalytics {
  const GetAnalytics(this.repository, this.access);
  final AnalyticsRepository repository;
  final AccessPolicy access;
  Future<AnalyticsSnapshot> call() {
    access.require(Permission.viewAnalytics);
    return repository.overview();
  }
}
