import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/data/mock_auth_repository.dart';
import '../../security/domain/security.dart';
import '../domain/candidates.dart';

final class MockCandidateRepository implements CandidateRepository {
  MockCandidateRepository(this.store, this.auth);
  final DemoStore store;
  final MockAuthRepository auth;
  @override
  Future<Page<Candidate>> search(
    CandidateFilter f, {
    required int offset,
    required int limit,
  }) async {
    final items = store.candidates
        .where(
          (c) =>
              c.openToOffers &&
              (!f.verifiedOnly || c.verified) &&
              (f.grade == null || c.grade == f.grade) &&
              (f.workFormat == null || c.workFormat == f.workFormat) &&
              (f.teamRole == null || c.teamRole == f.teamRole) &&
              (f.skill == null ||
                  c.skills.any(
                    (s) =>
                        s.toLowerCase().contains(f.skill!.trim().toLowerCase()),
                  )) &&
              (f.maxSalary == null ||
                  (c.salary != null &&
                      c.salary!.amount <= f.maxSalary!.amount)) &&
              (f.discipline == null ||
                  c.categories.any((v) => v.discipline == f.discipline)) &&
              (f.minLevel == null ||
                  c.categories.any((v) => v.level == f.minLevel)),
        )
        .toList();
    return Page(
      items: items.skip(offset).take(limit).toList(),
      total: items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<Candidate> details(EntityId id) async =>
      store.candidates.where((c) => c.id == id).firstOrNull ??
      (throw const AppFailure(FailureKind.notFound, 'candidate_not_found'));
  @override
  Future<Candidate> myProfile() => details(auth.profileId);
  @override
  Future<Candidate> update(ProfileDraft d) async {
    final old = await myProfile();
    final next = Candidate(
      id: old.id,
      name: d.name,
      headline: d.headline,
      city: d.city,
      grade: d.grade,
      workFormat: d.workFormat,
      teamRole: d.teamRole,
      salary: d.salary,
      skills: d.skills,
      about: d.about,
      openToOffers: d.openToOffers,
      fspId: d.fspId,
      // Changing FSP identity invalidates simulated verification.
      verified: old.fspId == d.fspId && old.verified,
      categories: old.fspId == d.fspId ? old.categories : [],
      achievements: old.fspId == d.fspId ? old.achievements : [],
      syncedAt: old.fspId == d.fspId ? old.syncedAt : null,
    );
    store.candidates[store.candidates.indexOf(old)] = next;
    return next;
  }

  @override
  Future<Candidate> syncFsp() async {
    final old = await myProfile();
    if (old.fspId?.trim().isEmpty ?? true) {
      throw const AppFailure(FailureKind.validation, 'fsp_id_required');
    }
    final next = Candidate(
      id: old.id,
      name: old.name,
      headline: old.headline,
      city: old.city,
      grade: old.grade,
      workFormat: old.workFormat,
      teamRole: old.teamRole,
      salary: old.salary,
      skills: old.skills,
      about: old.about,
      openToOffers: old.openToOffers,
      fspId: old.fspId,
      verified: true,
      syncedAt: DateTime.now().toUtc(),
      categories: const [
        TalentCategory(
          discipline: 'algorithmic',
          level: 'confirmed',
          score: 160,
          pointsToNextLevel: 40,
        ),
      ],
      achievements: [
        Achievement(
          'Demo programming championship',
          DateTime.utc(2026, 9, 20),
          'algorithmic',
          'first',
        ),
      ],
    );
    store.candidates[store.candidates.indexOf(old)] = next;
    store.notify(auth.current!.user.id, NotificationKind.verificationCompleted);
    return next;
  }

  @override
  Future<Dictionaries> dictionaries() async => Dictionaries({
    'disciplines': const [
      ReferenceOption('algorithmic', 'Algorithmic programming'),
      ReferenceOption('product', 'Product programming'),
    ],
    'verification_levels': const [ReferenceOption('confirmed', 'Confirmed')],
    'team_roles': const [
      ReferenceOption('mobile', 'Mobile'),
      ReferenceOption('backend', 'Backend'),
      ReferenceOption('frontend', 'Frontend'),
    ],
  });
}
