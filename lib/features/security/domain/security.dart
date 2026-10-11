enum NotificationKind {
  offerReceived,
  offerAccepted,
  offerRejected,
  matchCreated,
  verificationCompleted,
  securityAlert,
}

final class AppNotification {
  const AppNotification(this.id, this.kind, this.date, {this.read = false});
  final String id;
  final NotificationKind kind;
  final DateTime date;
  final bool read;
}

final class SecuritySnapshot {
  const SecuritySnapshot({
    required this.lastLogin,
    required this.activeSessions,
    required this.events,
  });
  final DateTime lastLogin;
  final int activeSessions;
  final List<AppNotification> events;
}

abstract interface class SecurityRepository {
  Future<SecuritySnapshot> overview();
  Future<List<AppNotification>> notifications();
  Future<void> markRead(String id);
}

abstract interface class PushNotificationProvider {
  Stream<AppNotification> get events;
  Future<void> registerDevice();
  Future<void> unregisterDevice();
}
