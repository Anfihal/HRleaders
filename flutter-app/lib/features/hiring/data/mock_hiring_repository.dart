import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/data/mock_auth_repository.dart';
import '../../security/domain/security.dart';
import '../domain/hiring.dart';

final class MockHiringRepository implements HiringRepository {
  MockHiringRepository(this.store, this.auth);
  final DemoStore store;
  final MockAuthRepository auth;
  @override
  Future<List<Vacancy>> vacancies() async => List.unmodifiable(
    store.vacancies.where(
      (v) => store.vacancyOwners[v.id] == auth.current!.user.id,
    ),
  );
  @override
  Future<Vacancy> createVacancy(VacancyDraft d) async {
    final vacancy = Vacancy(
      id: store.nextId(),
      title: d.title,
      salary: d.salary,
      isOpen: true,
      createdAt: DateTime.now().toUtc(),
      discipline: d.discipline,
      grade: d.grade,
      workFormat: d.workFormat,
      skills: d.skills,
      description: d.description,
    );
    store.vacancies.add(vacancy);
    store.vacancyOwners[vacancy.id] = auth.current!.user.id;
    return vacancy;
  }

  @override
  Future<Vacancy> closeVacancy(EntityId id) async {
    if (store.vacancyOwners[id] != auth.current!.user.id) {
      throw const AppFailure(FailureKind.forbidden, 'forbidden');
    }
    final old = store.vacancies.firstWhere((v) => v.id == id);
    final next = Vacancy(
      id: old.id,
      title: old.title,
      salary: old.salary,
      isOpen: false,
      createdAt: old.createdAt,
      discipline: old.discipline,
      grade: old.grade,
      workFormat: old.workFormat,
      skills: old.skills,
      description: old.description,
    );
    store.vacancies[store.vacancies.indexOf(old)] = next;
    return next;
  }

  @override
  Future<List<Offer>> offers({required bool incoming}) async =>
      List.unmodifiable(
        store.offers.where(
          (o) => incoming
              ? o.candidateId == auth.profileId
              : store.offerOwners[o.id] == auth.current!.user.id,
        ),
      );
  @override
  Future<Offer> send(OfferDraft draft) async {
    if (store.vacancyOwners[draft.vacancy.id] != auth.current!.user.id) {
      throw const AppFailure(FailureKind.forbidden, 'forbidden');
    }
    if (!store.vacancies.firstWhere((v) => v.id == draft.vacancy.id).isOpen) {
      throw const AppFailure(FailureKind.conflict, 'vacancy_closed');
    }
    if (store.offers.any(
      (o) =>
          o.vacancy.id == draft.vacancy.id &&
          o.candidateId == draft.candidateId &&
          o.awaitsResponse,
    )) {
      throw const AppFailure(FailureKind.conflict, 'duplicate_offer');
    }
    final candidate = store.candidates.firstWhere(
      (c) => c.id == draft.candidateId,
    );
    final offer = Offer(
      id: store.nextId(),
      candidateId: candidate.id,
      candidateName: candidate.name,
      companyName: auth.current!.user.company ?? '',
      vacancy: draft.vacancy,
      salary: draft.salary,
      message: draft.message,
      status: OfferStatus.sent,
      createdAt: DateTime.now().toUtc(),
    );
    store.offers.insert(0, offer);
    store.offerOwners[offer.id] = auth.current!.user.id;
    store.notify(
      candidate.id == store.candidates.first.id
          ? DemoStore.id(100)
          : candidate.id,
      NotificationKind.offerReceived,
    );
    return offer;
  }

  @override
  Future<Offer> respond(
    EntityId id,
    OfferStatus target, {
    String? reason,
  }) async {
    final old = store.offers.where((o) => o.id == id).firstOrNull;
    if (old == null) {
      throw const AppFailure(FailureKind.notFound, 'offer_not_found');
    }
    final owned = target == OfferStatus.withdrawn
        ? store.offerOwners[id] == auth.current!.user.id
        : old.candidateId == auth.profileId;
    if (!owned) throw const AppFailure(FailureKind.forbidden, 'forbidden');
    if (target == OfferStatus.viewed && old.status == OfferStatus.viewed) {
      return old;
    }
    final next = old.transition(target, DateTime.now().toUtc(), reason: reason);
    store.offers[store.offers.indexOf(old)] = next;
    if (target == OfferStatus.accepted || target == OfferStatus.declined) {
      store.notify(
        store.offerOwners[id]!,
        target == OfferStatus.accepted
            ? NotificationKind.offerAccepted
            : NotificationKind.offerRejected,
      );
      if (target == OfferStatus.accepted) {
        store.notify(auth.current!.user.id, NotificationKind.matchCreated);
      }
    }
    return next;
  }
}
