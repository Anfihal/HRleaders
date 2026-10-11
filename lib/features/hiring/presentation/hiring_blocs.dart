import '../../../core/domain/value_objects.dart';
import '../../../core/presentation/resource_state.dart';
import '../application/hiring_use_cases.dart';
import '../domain/hiring.dart';

final class VacanciesBloc extends ResourceBloc<List<Vacancy>> {
  VacanciesBloc(GetVacancies get, this.create, this.closeVacancy)
    : super(get.call, isEmpty: (v) => v.isEmpty);
  final CreateVacancy create;
  final CloseVacancy closeVacancy;
  Future<void> publish(VacancyDraft draft) => mutate(() async {
    await create(draft);
  });
  Future<void> closeItem(EntityId id) => mutate(() async {
    await closeVacancy(id);
  });
}

final class OffersBloc extends ResourceBloc<List<Offer>> {
  OffersBloc(GetOffers get, this.respond, {required this.incoming})
    : super(() => get(incoming: incoming), isEmpty: (v) => v.isEmpty);
  final RespondToOffer respond;
  final bool incoming;
  Future<void> action(EntityId id, OfferStatus target, {String? reason}) =>
      mutate(() async {
        await respond(id, target, reason: reason);
      });
}
