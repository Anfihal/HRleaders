import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../features/auth/domain/auth.dart';
import '../localization/localization.dart';

enum Destination {
  candidateHome('/candidate', Permission.viewOwnOffers, m.Icons.home_outlined),
  profile(
    '/candidate/profile',
    Permission.viewOwnProfile,
    m.Icons.person_outline,
  ),
  incoming('/candidate/offers', Permission.viewOwnOffers, m.Icons.mail_outline),
  candidateMatches(
    '/candidate/matches',
    Permission.viewOwnOffers,
    m.Icons.hub_outlined,
  ),
  employerHome('/employer', Permission.viewCandidates, m.Icons.home_outlined),
  candidates(
    '/employer/candidates',
    Permission.viewCandidates,
    m.Icons.people_outline,
  ),
  vacancies(
    '/employer/vacancies',
    Permission.manageVacancies,
    m.Icons.work_outline,
  ),
  sent('/employer/offers', Permission.viewEmployerOffers, m.Icons.mail_outline),
  employerMatches(
    '/employer/matches',
    Permission.viewEmployerOffers,
    m.Icons.hub_outlined,
  ),
  analytics('/employer/analytics', Permission.viewAnalytics, m.Icons.insights),
  company(
    '/employer/company',
    Permission.manageVacancies,
    m.Icons.business_outlined,
  ),
  messages('/messages', Permission.useMessaging, m.Icons.chat_bubble_outline),
  adminHome('/admin', Permission.viewAdmin, m.Icons.grid_view),
  users('/admin/users', Permission.viewUsers, m.Icons.people_outline),
  adminVacancies(
    '/admin/vacancies',
    Permission.moderateVacancies,
    m.Icons.work_outline,
  ),
  promotion('/admin/analytics', Permission.viewAdmin, m.Icons.insights),
  gateway('/admin/fsp', Permission.manageFsp, m.Icons.verified_outlined),
  audit('/admin/audit', Permission.viewAudit, m.Icons.history),
  security('/security', null, m.Icons.shield_outlined),
  notifications('/notifications', null, m.Icons.notifications_outlined),
  settings('/settings', null, m.Icons.settings_outlined);

  const Destination(this.path, this.permission, this.icon);
  final String path;
  final Permission? permission;
  final IconData icon;
  String label(BuildContext context) => switch (this) {
    candidateHome || employerHome || adminHome => context.l.home,
    profile => context.l.profile,
    incoming || sent => context.l.offers,
    candidateMatches || employerMatches => context.l.matches,
    candidates => context.l.candidates,
    vacancies || adminVacancies => context.l.vacancies,
    analytics || promotion => context.l.analytics,
    users => context.l.users,
    gateway => context.l.fsp,
    audit => context.l.audit,
    security => context.l.security,
    notifications => context.l.notifications,
    company => context.l.company,
    messages => context.l.messages,
    settings => context.l.settings,
  };
}

List<Destination> destinationsFor(User user) {
  final destinations = Destination.values
      .where(
        (d) =>
            (d.permission == null || user.can(d.permission!)) &&
            !(user.can(Permission.viewAdmin) && d == Destination.analytics),
      )
      .toList();
  if (user.can(Permission.viewAdmin)) {
    destinations.sort((a, b) {
      final groupA = a.path.startsWith('/admin') ? 0 : 1;
      final groupB = b.path.startsWith('/admin') ? 0 : 1;
      return groupA == groupB
          ? a.index.compareTo(b.index)
          : groupA.compareTo(groupB);
    });
  }
  return destinations;
}

String homeFor(User user) => user.can(Permission.viewAdmin)
    ? '/admin'
    : user.can(Permission.viewCandidates)
    ? '/employer'
    : '/candidate';

/// Normalize custom app links into the same guarded HTTPS route hierarchy.
String normalizeAppLink(Uri uri) {
  if (uri.scheme != 'hrleaders') return uri.path;
  return switch (uri.host) {
    'candidate' => '/employer/candidates${uri.path}',
    'vacancy' => '/employer/vacancies',
    'offer' => '/offer${uri.path}',
    _ => '/',
  };
}
