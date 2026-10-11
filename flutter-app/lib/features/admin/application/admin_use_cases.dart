import '../../../core/domain/value_objects.dart';
import '../../../core/security/access_policy.dart';
import '../../auth/domain/auth.dart';
import '../domain/admin.dart';
import '../../hiring/domain/hiring.dart';

final class GetModeratedVacancies {
  const GetModeratedVacancies(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<List<Vacancy>> call() {
    access.require(Permission.moderateVacancies);
    return repository.vacancies();
  }
}

final class ModerateVacancy {
  const ModerateVacancy(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<void> call(EntityId id) {
    access.require(Permission.moderateVacancies);
    return repository.moderateVacancy(id);
  }
}

final class GetAdminDashboard {
  const GetAdminDashboard(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<AdminSnapshot> call() {
    access.require(Permission.viewAdmin);
    return repository.dashboard();
  }
}

final class GetUsers {
  const GetUsers(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<List<AdminUser>> call() {
    access.require(Permission.viewUsers);
    return repository.users();
  }
}

final class BlockUser {
  const BlockUser(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<void> call(EntityId id, bool blocked) {
    access.require(Permission.manageUsers);
    return repository.setBlocked(id, blocked);
  }
}

final class GetFspGatewayStatus {
  const GetFspGatewayStatus(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<GatewaySnapshot> call() {
    access.require(Permission.manageFsp);
    return repository.gateway();
  }
}

final class GetAuditLog {
  const GetAuditLog(this.repository, this.access);
  final AdminRepository repository;
  final AccessPolicy access;
  Future<List<AuditEvent>> call() {
    access.require(Permission.viewAudit);
    return repository.audit();
  }
}
