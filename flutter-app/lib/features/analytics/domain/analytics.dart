final class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.candidates,
    required this.verified,
    required this.views,
    required this.sent,
    required this.opened,
    required this.accepted,
    this.averageResponseHours,
  });
  final int candidates;
  final int verified;
  final int views;
  final int sent;
  final int opened;
  final int accepted;
  final double? averageResponseHours;
  double? get acceptance => sent == 0 ? null : accepted / sent;
  double? get verifiedShare => candidates == 0 ? null : verified / candidates;
}

abstract interface class AnalyticsRepository {
  Future<AnalyticsSnapshot> overview();
}
