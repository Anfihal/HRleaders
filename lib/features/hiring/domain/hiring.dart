import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../candidates/domain/candidates.dart';

enum OfferStatus { sent, viewed, accepted, declined, withdrawn }

final class Vacancy {
  Vacancy({
    required this.id,
    required this.title,
    required this.salary,
    required this.isOpen,
    required this.createdAt,
    this.discipline,
    this.grade,
    this.workFormat,
    List<String> skills = const [],
    this.description = '',
  }) : skills = List.unmodifiable(skills);
  final EntityId id;
  final String title;
  final SalaryRange salary;
  final bool isOpen;
  final DateTime createdAt;
  final String? discipline;
  final Grade? grade;
  final WorkFormat? workFormat;
  final List<String> skills;
  final String description;
}

final class VacancyDraft {
  VacancyDraft({
    required this.title,
    required this.salary,
    this.discipline,
    this.grade,
    this.workFormat,
    this.skills = const [],
    this.description = '',
  }) {
    if (title.trim().length < 3 ||
        title.length > 200 ||
        skills.length > 30 ||
        description.length > 4000) {
      throw const AppFailure(FailureKind.validation, 'invalid_vacancy');
    }
  }
  final String title;
  final SalaryRange salary;
  final String? discipline;
  final Grade? grade;
  final WorkFormat? workFormat;
  final List<String> skills;
  final String description;
}

final class Offer {
  const Offer({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    required this.companyName,
    required this.vacancy,
    required this.salary,
    required this.message,
    required this.status,
    required this.createdAt,
    this.viewedAt,
    this.respondedAt,
    this.declineReason,
  });
  final EntityId id;
  final EntityId candidateId;
  final String candidateName;
  final String companyName;
  final Vacancy vacancy;
  final Salary salary;
  final String message;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final String? declineReason;
  bool get awaitsResponse =>
      status == OfferStatus.sent || status == OfferStatus.viewed;

  Offer transition(OfferStatus target, DateTime now, {String? reason}) {
    if (!awaitsResponse ||
        (target != OfferStatus.viewed &&
            target != OfferStatus.accepted &&
            target != OfferStatus.declined &&
            target != OfferStatus.withdrawn)) {
      throw const AppFailure(
        FailureKind.conflict,
        'offer_transition_not_allowed',
      );
    }
    if (target == OfferStatus.declined && (reason?.trim().isEmpty ?? true)) {
      throw const AppFailure(FailureKind.validation, 'decline_reason_required');
    }
    return Offer(
      id: id,
      candidateId: candidateId,
      candidateName: candidateName,
      companyName: companyName,
      vacancy: vacancy,
      salary: salary,
      message: message,
      status: target,
      createdAt: createdAt,
      viewedAt: viewedAt ?? now,
      respondedAt: target == OfferStatus.viewed ? null : now,
      declineReason: reason?.trim(),
    );
  }
}

final class OfferDraft {
  OfferDraft({
    required this.vacancy,
    required this.candidateId,
    required this.salary,
    required this.message,
  }) {
    if (!vacancy.isOpen) {
      throw const AppFailure(FailureKind.conflict, 'vacancy_closed');
    }
    if (!vacancy.salary.contains(salary)) {
      throw const AppFailure(
        FailureKind.validation,
        'offer_salary_out_of_range',
      );
    }
    if (message.trim().length < 10 || message.length > 2000) {
      throw const AppFailure(FailureKind.validation, 'invalid_message');
    }
  }
  final Vacancy vacancy;
  final EntityId candidateId;
  final Salary salary;
  final String message;
}

final class Match {
  const Match._(this.offer);
  factory Match.fromOffer(Offer offer) {
    if (offer.status != OfferStatus.accepted) {
      throw const AppFailure(FailureKind.validation, 'offer_not_accepted');
    }
    return Match._(offer);
  }
  final Offer offer;
}

abstract interface class HiringRepository {
  Future<List<Vacancy>> vacancies();
  Future<Vacancy> createVacancy(VacancyDraft draft);
  Future<Vacancy> closeVacancy(EntityId id);
  Future<List<Offer>> offers({required bool incoming});
  Future<Offer> send(OfferDraft draft);
  Future<Offer> respond(EntityId id, OfferStatus target, {String? reason});
}
