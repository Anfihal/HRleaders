import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/security/access_policy.dart';
import '../../auth/domain/auth.dart';
import '../domain/hiring.dart';

final class GetVacancies {
  const GetVacancies(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<List<Vacancy>> call() {
    access.require(Permission.manageVacancies);
    return repository.vacancies();
  }
}

final class CreateVacancy {
  const CreateVacancy(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<Vacancy> call(VacancyDraft draft) {
    access.require(Permission.manageVacancies);
    return repository.createVacancy(draft);
  }
}

final class CloseVacancy {
  const CloseVacancy(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<Vacancy> call(EntityId id) {
    access.require(Permission.manageVacancies);
    return repository.closeVacancy(id);
  }
}

final class GetOffers {
  const GetOffers(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<List<Offer>> call({required bool incoming}) {
    access.require(
      incoming ? Permission.viewOwnOffers : Permission.viewEmployerOffers,
    );
    return repository.offers(incoming: incoming);
  }
}

final class SendOffer {
  const SendOffer(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<Offer> call(OfferDraft draft) {
    access.require(Permission.sendOffers);
    return repository.send(draft);
  }
}

final class RespondToOffer {
  const RespondToOffer(this.repository, this.access);
  final HiringRepository repository;
  final AccessPolicy access;
  Future<Offer> call(EntityId id, OfferStatus target, {String? reason}) {
    if (target == OfferStatus.sent) {
      throw const AppFailure(FailureKind.validation, 'invalid_action');
    }
    access.require(
      target == OfferStatus.withdrawn
          ? Permission.sendOffers
          : Permission.respondOffers,
    );
    if (target == OfferStatus.declined &&
        ((reason?.trim().isEmpty ?? true) || reason!.length > 1000)) {
      throw const AppFailure(FailureKind.validation, 'decline_reason_required');
    }
    return repository.respond(id, target, reason: reason);
  }
}

final class GetMatches {
  const GetMatches(this.offers);
  final GetOffers offers;
  Future<List<Match>> call({required bool incoming}) async =>
      (await offers(incoming: incoming))
          .where((offer) => offer.status == OfferStatus.accepted)
          .map(Match.fromOffer)
          .toList(growable: false);
}
