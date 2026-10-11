import '../../../core/domain/value_objects.dart';
import '../../auth/domain/auth.dart';
import '../../hiring/domain/hiring.dart';

enum GatewayStatus { online, degraded, offline }

enum RegionCode { moscow, petersburg, kazan, novosibirsk }

final class RegionMetric {
  const RegionMetric(this.region, this.count);
  final RegionCode region;
  final int count;
}

final class GatewaySnapshot {
  const GatewaySnapshot({
    required this.status,
    required this.lastSync,
    required this.queue,
    required this.errors,
    required this.requests,
    required this.latencyMs,
  });
  final GatewayStatus status;
  final DateTime lastSync;
  final int queue;
  final int errors;
  final int requests;
  final int latencyMs;
}

final class AdminUser {
  const AdminUser(this.user, {this.blocked = false});
  final User user;
  final bool blocked;
}

final class AuditEvent {
  const AuditEvent(this.id, this.date, this.actorId, this.action);
  final String id;
  final DateTime date;
  final EntityId actorId;
  final String action;
}

final class AdminSnapshot {
  const AdminSnapshot({
    required this.users,
    required this.candidates,
    required this.hr,
    required this.vacancies,
    required this.matches,
    required this.verificationRate,
    required this.averageMatchHours,
    required this.regions,
  });
  final int users;
  final int candidates;
  final int hr;
  final int vacancies;
  final int matches;
  final double verificationRate;
  final double? averageMatchHours;
  final List<RegionMetric> regions;
}

abstract interface class AdminRepository {
  Future<List<Vacancy>> vacancies();
  Future<void> moderateVacancy(EntityId id);
  Future<AdminSnapshot> dashboard();
  Future<List<AdminUser>> users();
  Future<void> setBlocked(EntityId id, bool blocked);
  Future<GatewaySnapshot> gateway();
  Future<List<AuditEvent>> audit();
}
