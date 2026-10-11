import '../../../core/domain/value_objects.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../../candidates/domain/candidates.dart';
import '../domain/hiring.dart';

final class VacancyDto {
  VacancyDto(Object? json) : _json = JsonReader(json);
  final JsonReader _json;
  Vacancy toDomain() => Vacancy(
    id: EntityId(_json.string('id')),
    title: _json.string('title'),
    salary: SalaryRange(
      _json.integer('salary_from'),
      _json.integer('salary_to'),
    ),
    isOpen: _json.boolean('is_open'),
    createdAt: _json.date('created_at'),
    discipline: _json.optionalString('discipline_code'),
    grade: _json.optionalEnum('grade', Grade.values),
    workFormat: _json.optionalEnum('work_format', WorkFormat.values),
    skills: _json.strings('skills'),
    description: _json.string('description'),
  );
}

final class OfferDto {
  OfferDto(Object? json) : _json = JsonReader(json);
  final JsonReader _json;
  Offer toDomain() => Offer(
    id: EntityId(_json.string('id')),
    candidateId: EntityId(_json.string('candidate_id')),
    candidateName: _json.string('candidate_name'),
    companyName: _json.string('company_name'),
    vacancy: VacancyDto(_json.data['vacancy']).toDomain(),
    salary: Salary(_json.integer('salary')),
    message: _json.string('message'),
    status: _json.enumeration('status', OfferStatus.values),
    createdAt: _json.date('created_at'),
    viewedAt: _json.optionalDate('viewed_at'),
    respondedAt: _json.optionalDate('responded_at'),
    declineReason: _json.optionalString('decline_reason'),
  );
}

final class HiringApiDataSource {
  const HiringApiDataSource(this.api);
  final ApiClient api;
  Future<List<Vacancy>> vacancies() async => decodeList(
    await api.request('GET', 'vacancies'),
    (item) => VacancyDto(item).toDomain(),
  );
  Future<Vacancy> create(VacancyDraft d) async => VacancyDto(
    await api.request(
      'POST',
      'vacancies',
      body: {
        'title': d.title,
        'salary_from': d.salary.from.amount,
        'salary_to': d.salary.to.amount,
        'discipline_code': d.discipline,
        'grade': d.grade?.name,
        'work_format': d.workFormat?.name,
        'skills': d.skills,
        'description': d.description,
      },
    ),
  ).toDomain();
  Future<Vacancy> close(EntityId id) async =>
      VacancyDto(await api.request('POST', 'vacancies/${id.value}/close'))
          .toDomain();
  Future<List<Offer>> offers(bool incoming) async => decodeList(
    await api.request('GET', incoming ? 'offers/incoming' : 'offers'),
    (item) => OfferDto(item).toDomain(),
  );
  Future<Offer> send(OfferDraft d) async => OfferDto(
    await api.request(
      'POST',
      'offers',
      body: {
        'vacancy_id': d.vacancy.id.value,
        'candidate_id': d.candidateId.value,
        'salary': d.salary.amount,
        'message': d.message,
      },
    ),
  ).toDomain();
  Future<Offer> respond(EntityId id, OfferStatus target, String? reason) async {
    final action = switch (target) {
      OfferStatus.viewed => 'view',
      OfferStatus.accepted => 'accept',
      OfferStatus.declined => 'decline',
      OfferStatus.withdrawn => 'withdraw',
      OfferStatus.sent => throw ArgumentError.value(target),
    };
    return OfferDto(
      await api.request(
        'POST',
        'offers/${id.value}/$action',
        body: target == OfferStatus.declined ? {'reason': reason} : null,
      ),
    ).toDomain();
  }
}

final class RemoteHiringRepository implements HiringRepository {
  const RemoteHiringRepository(this.source);
  final HiringApiDataSource source;
  @override
  Future<List<Vacancy>> vacancies() => source.vacancies();
  @override
  Future<Vacancy> createVacancy(VacancyDraft draft) => source.create(draft);
  @override
  Future<Vacancy> closeVacancy(EntityId id) => source.close(id);
  @override
  Future<List<Offer>> offers({required bool incoming}) =>
      source.offers(incoming);
  @override
  Future<Offer> send(OfferDraft draft) => source.send(draft);
  @override
  Future<Offer> respond(EntityId id, OfferStatus target, {String? reason}) =>
      source.respond(id, target, reason);
}
