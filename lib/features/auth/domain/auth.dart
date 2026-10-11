import '../../../core/domain/value_objects.dart';

enum Permission {
  viewOwnProfile,
  viewCandidates,
  manageVacancies,
  sendOffers,
  respondOffers,
  viewOwnOffers,
  viewEmployerOffers,
  viewAnalytics,
  viewAdmin,
  viewUsers,
  manageUsers,
  moderateVacancies,
  viewAudit,
  manageFsp,
  manageSecurity,
  useMessaging,
}

enum Role {
  candidate,
  hr,
  admin,
  analyst,
  superadmin;

  Set<Permission> get permissions => switch (this) {
    Role.candidate => {
      Permission.viewOwnProfile,
      Permission.viewOwnOffers,
      Permission.respondOffers,
      Permission.useMessaging,
    },
    Role.hr => {
      Permission.viewCandidates,
      Permission.manageVacancies,
      Permission.sendOffers,
      Permission.viewEmployerOffers,
      Permission.viewAnalytics,
      Permission.useMessaging,
    },
    Role.analyst => {Permission.viewAdmin, Permission.viewAnalytics},
    Role.admin => {
      Permission.viewAdmin,
      Permission.viewUsers,
      Permission.manageUsers,
      Permission.moderateVacancies,
      Permission.viewAnalytics,
      Permission.viewAudit,
      Permission.manageFsp,
      Permission.manageSecurity,
    },
    Role.superadmin => Permission.values.toSet(),
  };
}

final class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.company,
  });
  final EntityId id;
  final Email email;
  final String name;
  final Role role;
  final String? company;
  bool can(Permission permission) => role.permissions.contains(permission);
}

final class Session {
  const Session(this.user, {this.isDemo = false});
  final User user;
  final bool isDemo;
}

final class Registration {
  const Registration({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.company,
  });
  final Email email;
  final String password;
  final String name;
  final Role role;
  final String? company;
}

abstract interface class AuthRepository {
  Session? get current;
  Future<Session?> restore();
  Future<Session> login(Email email, String password);
  Future<Session> register(Registration registration);
  Future<void> logout();
  Future<void> expire();
}

/// A future backend adapter may implement renewal when a contract exists.
abstract interface class SessionRenewal {
  Future<Session> renew();
}
