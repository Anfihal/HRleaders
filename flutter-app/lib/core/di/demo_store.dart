import '../../features/auth/domain/auth.dart';
import '../../features/candidates/domain/candidates.dart';
import '../../features/hiring/domain/hiring.dart';
import '../../features/admin/domain/admin.dart';
import '../../features/security/domain/security.dart';
import '../../features/assessments/domain/assessments.dart';
import '../../features/recruiter_assistant/domain/recruiter_assistant.dart';
import '../../features/recruiter_cjm/domain/recruiter_cjm.dart';
import '../domain/value_objects.dart';

/// Application-scoped demo state, never a global and never used as API fallback.
final class DemoStore {
  DemoStore() {
    users.addAll(
      Role.values.map(
        (role) => AdminUser(
          User(
            id: id(100 + role.index),
            email: Email('${role.name}@demo.hrleaders.example'),
            name: role.name,
            role: role,
            company: role == Role.hr ? 'Radius Software (demo)' : null,
          ),
        ),
      ),
    );
    for (final account in users) {
      passwords[account.user.email.value] = 'Demo12345';
    }
    for (var index = 0; index < 45; index++) {
      candidates.add(
        Candidate(
          id: id(200 + index),
          name: index == 0 ? 'Daria Orlova' : 'Specialist ${index + 1}',
          headline: index.isEven
              ? 'Flutter / Dart engineer'
              : 'Python backend engineer',
          city: ['Moscow', 'Kazan', 'Novosibirsk'][index % 3],
          grade: Grade.values[index % 4],
          workFormat: WorkFormat.remote,
          teamRole: index.isEven ? 'mobile' : 'backend',
          salary: Salary(180000 + index * 3000),
          skills: index.isEven ? ['Dart', 'Flutter', 'SQL'] : ['Python', 'SQL'],
          verified: index % 3 != 2,
          about: 'Sports programming and reliable product engineering.',
          fspId: 'DEMO-${index + 1}',
          syncedAt: DateTime.utc(2026, 10, 1),
          categories: index % 3 == 2
              ? []
              : [
                  const TalentCategory(
                    discipline: 'algorithmic',
                    level: 'confirmed',
                    score: 160,
                    pointsToNextLevel: 40,
                  ),
                ],
          achievements: index % 3 == 2
              ? []
              : [
                  Achievement(
                    'Demo programming championship',
                    DateTime.utc(2026, 9, 20),
                    'algorithmic',
                    'first',
                  ),
                ],
        ),
      );
    }
    vacancies.add(
      Vacancy(
        id: id(400),
        title: 'Flutter engineer',
        salary: SalaryRange(180000, 350000),
        isOpen: true,
        createdAt: DateTime.utc(2026, 10, 1),
        workFormat: WorkFormat.remote,
        skills: ['Dart', 'Flutter'],
        description:
            'Build accessible products with a thoughtful engineering team.',
      ),
    );
    vacancyOwners[vacancies.first.id] = users
        .firstWhere((u) => u.user.role == Role.hr)
        .user
        .id;
    offers.add(
      Offer(
        id: id(500),
        candidateId: candidates.first.id,
        candidateName: candidates.first.name,
        companyName: 'Radius Software (demo)',
        vacancy: vacancies.first,
        salary: Salary(250000),
        message: 'We value your verified achievements. Let’s build the next product together.',
        status: OfferStatus.sent,
        createdAt: DateTime.utc(2026, 10, 2),
      ),
    );
    offerOwners[offers.first.id] = vacancyOwners[vacancies.first.id]!;
    notify(users.first.user.id, NotificationKind.offerReceived);
  }
  final List<AdminUser> users = [];
  // Demo credentials exist only in this explicitly selected in-memory adapter.
  final Map<String, String> passwords = {};
  final List<Candidate> candidates = [];
  final List<AssessmentAttempt> assessmentAttempts = [];
  final List<(EntityId, TrackedCandidate)> trackedCandidates = [];
  final List<AssessmentAssignment> assessmentAssignments = [];
  final List<RecruiterMessage> recruiterMessages = [];
  final List<Vacancy> vacancies = [];
  final List<Offer> offers = [];
  final Map<EntityId, EntityId> vacancyOwners = {};
  final Map<EntityId, EntityId> offerOwners = {};
  final List<AuditEvent> audit = [];
  final Map<EntityId, List<AppNotification>> notifications = {};
  int _sequence = 1000;
  EntityId nextId() => id(++_sequence);
  static EntityId id(int value) =>
      EntityId('00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}');
  void notify(EntityId userId, NotificationKind kind) {
    notifications
        .putIfAbsent(userId, () => [])
        .insert(
          0,
          AppNotification(nextId().value, kind, DateTime.now().toUtc()),
        );
  }
}
