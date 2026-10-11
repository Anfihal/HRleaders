import '../../../core/di/demo_store.dart';
import '../../auth/domain/auth.dart';
import '../domain/security.dart';

final class MockSecurityRepository implements SecurityRepository {
  const MockSecurityRepository(this.store, this.auth);
  final DemoStore store;
  final AuthRepository auth;
  @override
  Future<SecuritySnapshot> overview() async => SecuritySnapshot(
    lastLogin: DateTime.utc(2026, 10, 8),
    activeSessions: 1,
    events: (await notifications())
        .where((n) => n.kind == NotificationKind.securityAlert)
        .toList(),
  );
  @override
  Future<List<AppNotification>> notifications() async =>
      List.unmodifiable(store.notifications[auth.current!.user.id] ?? []);
  @override
  Future<void> markRead(String id) async {
    final list = store.notifications[auth.current!.user.id] ?? [];
    final index = list.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final old = list[index];
      list[index] = AppNotification(old.id, old.kind, old.date, read: true);
    }
  }
}
