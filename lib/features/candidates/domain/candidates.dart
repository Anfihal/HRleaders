import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';

enum Grade { junior, middle, senior, lead }

enum WorkFormat { office, hybrid, remote }

final class TalentCategory {
  const TalentCategory({
    required this.discipline,
    required this.level,
    required this.score,
    this.pointsToNextLevel,
  });
  final String discipline;
  final String level;
  final double score;
  final double? pointsToNextLevel;
}

final class Achievement {
  const Achievement(this.competition, this.date, this.discipline, this.result);
  final String competition;
  final DateTime date;
  final String discipline;
  final String result;
}

final class Candidate {
  Candidate({
    required this.id,
    required this.name,
    required this.headline,
    this.city,
    this.grade,
    this.workFormat,
    this.teamRole,
    this.salary,
    List<String> skills = const [],
    this.verified = false,
    List<TalentCategory> categories = const [],
    this.about,
    this.openToOffers = true,
    this.fspId,
    this.syncedAt,
    List<Achievement> achievements = const [],
  }) : skills = List.unmodifiable(skills),
       categories = List.unmodifiable(categories),
       achievements = List.unmodifiable(achievements);
  final EntityId id;
  final String name;
  final String headline;
  final String? city;
  final Grade? grade;
  final WorkFormat? workFormat;
  final String? teamRole;
  final Salary? salary;
  final List<String> skills;
  final bool verified;
  final List<TalentCategory> categories;
  final String? about;
  final bool openToOffers;
  final String? fspId;
  final DateTime? syncedAt;
  final List<Achievement> achievements;
}

final class CandidateFilter {
  const CandidateFilter({
    this.discipline,
    this.minLevel,
    this.grade,
    this.teamRole,
    this.workFormat,
    this.skill,
    this.maxSalary,
    this.verifiedOnly = false,
  });
  final String? discipline;
  final String? minLevel;
  final Grade? grade;
  final String? teamRole;
  final WorkFormat? workFormat;
  final String? skill;
  final Salary? maxSalary;
  final bool verifiedOnly;
}

final class ProfileDraft {
  ProfileDraft({
    required this.name,
    required this.headline,
    this.city,
    this.grade,
    this.workFormat,
    this.teamRole,
    this.salary,
    List<String> skills = const [],
    this.about,
    this.openToOffers = true,
    this.fspId,
  }) : skills = List.unmodifiable(skills) {
    if (name.trim().length < 2 ||
        name.length > 200 ||
        headline.trim().length < 2 ||
        headline.length > 200 ||
        skills.length > 30 ||
        (about?.length ?? 0) > 4000) {
      throw const AppFailure(FailureKind.validation, 'invalid_profile');
    }
  }
  final String name;
  final String headline;
  final String? city;
  final Grade? grade;
  final WorkFormat? workFormat;
  final String? teamRole;
  final Salary? salary;
  final List<String> skills;
  final String? about;
  final bool openToOffers;
  final String? fspId;
}

final class ReferenceOption {
  const ReferenceOption(this.code, this.label);
  final String code;
  final String label;
}

final class Dictionaries {
  Dictionaries(Map<String, List<ReferenceOption>> groups)
    : groups = Map<String, List<ReferenceOption>>.unmodifiable(
        groups.map(
          (k, v) => MapEntry(k, List<ReferenceOption>.unmodifiable(v)),
        ),
      );
  final Map<String, List<ReferenceOption>> groups;
  List<ReferenceOption> options(String group) => groups[group] ?? const [];
  String label(String group, String code) =>
      options(group).where((item) => item.code == code).firstOrNull?.label ??
      code;
}

abstract interface class CandidateRepository {
  Future<Page<Candidate>> search(
    CandidateFilter filter, {
    required int offset,
    required int limit,
  });
  Future<Candidate> details(EntityId id);
  Future<Candidate> myProfile();
  Future<Candidate> update(ProfileDraft draft);
  Future<Candidate> syncFsp();
  Future<Dictionaries> dictionaries();
}
