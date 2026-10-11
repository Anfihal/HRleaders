import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../features/auth/domain/auth.dart';
import '../../features/candidates/domain/candidates.dart';
import '../../features/hiring/domain/hiring.dart';
import '../error/app_failure.dart';
import 'generated/app_localizations.dart';

extension AppLocalization on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  String referenceLabel(String code, {String? fallback}) => switch (code) {
    'algorithmic' || 'algorithms' => l.algorithmic,
    'product' => l.productProgramming,
    'security' => l.securityProgramming,
    'robotics' => l.robotics,
    'uav' => l.uav,
    'none' => l.unverified,
    'basic' => l.levelBasic,
    'confirmed' => l.verified,
    'advanced' => l.levelAdvanced,
    'expert' => l.levelExpert,
    'winner' => l.resultWinner,
    'prize_winner' => l.resultPrizeWinner,
    'finalist' => l.resultFinalist,
    'participant' => l.resultParticipant,
    'first' => l.resultFirst,
    _ => fallback ?? code,
  };
  String money(int amount) => NumberFormat.currency(
    locale: l.localeName,
    name: 'RUB',
    symbol: l.localeName == 'ru' ? '₽' : 'RUB',
    decimalDigits: 0,
  ).format(amount);
  String number(num value) =>
      NumberFormat.decimalPattern(l.localeName).format(value);
  String date(DateTime date) =>
      DateFormat.yMMMd(l.localeName).format(date.toLocal());
  String percent(double value) =>
      NumberFormat.percentPattern(l.localeName).format(value);
  String roleLabel(Role role) => switch (role) {
    Role.candidate => l.candidate,
    Role.hr => l.employer,
    Role.admin => l.administrator,
    Role.analyst => l.analyst,
    Role.superadmin => l.superadmin,
  };
  String gradeLabel(Grade grade) => switch (grade) {
    Grade.junior => l.junior,
    Grade.middle => l.middle,
    Grade.senior => l.senior,
    Grade.lead => l.lead,
  };
  String formatLabel(WorkFormat format) => switch (format) {
    WorkFormat.office => l.office,
    WorkFormat.hybrid => l.hybrid,
    WorkFormat.remote => l.remote,
  };
  String statusLabel(OfferStatus status) => switch (status) {
    OfferStatus.sent => l.sent,
    OfferStatus.viewed => l.viewed,
    OfferStatus.accepted => l.accepted,
    OfferStatus.declined => l.declined,
    OfferStatus.withdrawn => l.withdrawn,
  };
  String failureLabel(AppFailure failure) {
    if (failure.code == 'invalid_credentials') return l.invalidCredentials;
    return switch (failure.kind) {
      FailureKind.validation => l.invalidForm,
      FailureKind.unauthenticated => l.sessionExpired,
      FailureKind.forbidden => l.forbidden,
      FailureKind.notFound => l.notFound,
      FailureKind.conflict => l.conflict,
      FailureKind.unavailable => l.networkError,
      FailureKind.unsupported => l.unsupported,
      FailureKind.malformed => l.malformed,
    };
  }
}
