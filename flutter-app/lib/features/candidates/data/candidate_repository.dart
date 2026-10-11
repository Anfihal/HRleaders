import '../../../core/domain/value_objects.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../domain/candidates.dart';

final class CandidateDto {
  CandidateDto(Object? json) : _json = JsonReader(json);
  final JsonReader _json;
  Candidate toDomain() => Candidate(
    id: EntityId(_json.string('id')),
    name: _json.string('full_name'),
    headline: _json.string('headline'),
    city: _json.optionalString('city'),
    grade: _json.optionalEnum('grade', Grade.values),
    teamRole: _json.optionalString('team_role'),
    workFormat: _json.optionalEnum('work_format', WorkFormat.values),
    salary: switch (_json.optionalInteger('salary_expectation')) {
      final int amount => Salary(amount),
      null => null,
    },
    skills: _json.strings('skills'),
    verified: _json.boolean('is_fsp_verified'),
    about: _json.optionalString('about'),
    openToOffers: _json.boolean('open_to_offers', fallback: true),
    fspId: _json.optionalString('fsp_participant_id'),
    syncedAt: _json.optionalDate('fsp_synced_at'),
    categories: _json.list('categories').map((raw) {
      final category = JsonReader(raw);
      return TalentCategory(
        discipline: category.string('discipline_code'),
        level: category.object('level').string('code'),
        score: category.decimal('score'),
        pointsToNextLevel: category.optionalDecimal('points_to_next_level'),
      );
    }).toList(),
    achievements: _json.data['achievements'] == null
        ? []
        : _json.list('achievements').map((raw) {
            final achievement = JsonReader(raw);
            return Achievement(
              achievement.string('competition_name'),
              achievement.date('held_on'),
              achievement.string('discipline_code'),
              achievement.string('result_code'),
            );
          }).toList(),
  );
}

final class CandidateApiDataSource {
  const CandidateApiDataSource(this.api);
  final ApiClient api;
  Future<Page<Candidate>> search(
    CandidateFilter filter,
    int offset,
    int limit,
  ) async {
    final response = JsonReader(
      await api.request(
        'GET',
        'candidates',
        query: {
          'offset': '$offset',
          'limit': '$limit',
          'verified_only': '${filter.verifiedOnly}',
          if (filter.discipline != null) 'discipline': filter.discipline!,
          if (filter.minLevel != null) 'min_level': filter.minLevel!,
          if (filter.grade != null) 'grade': filter.grade!.name,
          if (filter.teamRole != null) 'team_role': filter.teamRole!,
          if (filter.workFormat != null) 'work_format': filter.workFormat!.name,
          if (filter.skill?.trim().isNotEmpty ?? false)
            'skill': filter.skill!.trim(),
          if (filter.maxSalary != null)
            'max_salary': '${filter.maxSalary!.amount}',
        },
      ),
    );
    return Page(
      items: response
          .list('items')
          .map((item) => CandidateDto(item).toDomain())
          .toList(),
      total: response.integer('total'),
      offset: response.integer('offset'),
      limit: response.integer('limit'),
    );
  }

  Future<Candidate> get(String path) async =>
      CandidateDto(await api.request('GET', path)).toDomain();
  Future<Candidate> update(ProfileDraft d) async => CandidateDto(
    await api.request(
      'PUT',
      'candidates/me',
      body: {
        'full_name': d.name.trim(),
        'headline': d.headline.trim(),
        'city': d.city,
        'grade': d.grade?.name,
        'team_role': d.teamRole,
        'work_format': d.workFormat?.name,
        'salary_expectation': d.salary?.amount,
        'skills': d.skills,
        'about': d.about,
        'open_to_offers': d.openToOffers,
        'fsp_participant_id': d.fspId,
      },
    ),
  ).toDomain();
  Future<Candidate> sync() async => CandidateDto(
    JsonReader(await api.request('POST', 'candidates/me/fsp-sync'))
        .data['profile'],
  ).toDomain();
  Future<Dictionaries> dictionaries() async {
    final response = JsonReader(await api.request('GET', 'dictionaries'));
    return Dictionaries(
      response.data.map<String, List<ReferenceOption>>(
        (key, value) => MapEntry(
          key,
          decodeList<ReferenceOption>(value, (item) {
            final option = JsonReader(item);
            return ReferenceOption(
              option.string('code'),
              option.string('label'),
            );
          }),
        ),
      ),
    );
  }
}

final class RemoteCandidateRepository implements CandidateRepository {
  const RemoteCandidateRepository(this.source);
  final CandidateApiDataSource source;
  @override
  Future<Page<Candidate>> search(
    CandidateFilter f, {
    required int offset,
    required int limit,
  }) => source.search(f, offset, limit);
  @override
  Future<Candidate> details(EntityId id) =>
      source.get('candidates/${Uri.encodeComponent(id.value)}');
  @override
  Future<Candidate> myProfile() => source.get('candidates/me');
  @override
  Future<Candidate> update(ProfileDraft draft) => source.update(draft);
  @override
  Future<Candidate> syncFsp() => source.sync();
  @override
  Future<Dictionaries> dictionaries() => source.dictionaries();
}
