import '../../../core/di/demo_store.dart';
import '../../auth/domain/auth.dart';
import '../../hiring/domain/hiring.dart';
import '../domain/analytics.dart';

final class MockAnalyticsRepository implements AnalyticsRepository {
  const MockAnalyticsRepository(this.store, this.auth);
  final DemoStore store;
  final AuthRepository auth;
  @override
  Future<AnalyticsSnapshot> overview() async {
    final offers = store.offers
        .where((o) => store.offerOwners[o.id] == auth.current!.user.id)
        .toList();
    return AnalyticsSnapshot(
      candidates: store.candidates.where((c) => c.openToOffers).length,
      verified: store.candidates
          .where((c) => c.openToOffers && c.verified)
          .length,
      views: 18,
      sent: offers.length,
      opened: offers.where((o) => o.viewedAt != null).length,
      accepted: offers.where((o) => o.status == OfferStatus.accepted).length,
    );
  }
}
