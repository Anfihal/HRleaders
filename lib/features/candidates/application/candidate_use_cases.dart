import '../../../core/domain/value_objects.dart';
import '../../../core/security/access_policy.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/domain/auth.dart';
import '../domain/candidates.dart';

final class SearchCandidates {
  const SearchCandidates(this.repository, this.access);
  final CandidateRepository repository;
  final AccessPolicy access;
  Future<Page<Candidate>> call(
    CandidateFilter filter, {
    int offset = 0,
    int limit = 20,
  }) {
    access.require(Permission.viewCandidates);
    if (offset < 0 || limit < 1 || limit > 100) {
      throw const AppFailure(FailureKind.validation, 'invalid_page');
    }
    return repository.search(filter, offset: offset, limit: limit);
  }
}

final class GetCandidateDetails {
  const GetCandidateDetails(this.repository, this.access);
  final CandidateRepository repository;
  final AccessPolicy access;
  Future<Candidate> call(EntityId id) {
    access.require(Permission.viewCandidates);
    return repository.details(id);
  }
}

final class GetCandidateProfile {
  const GetCandidateProfile(this.repository, this.access);
  final CandidateRepository repository;
  final AccessPolicy access;
  Future<Candidate> call() {
    access.require(Permission.viewOwnProfile);
    return repository.myProfile();
  }
}

final class UpdateCandidateProfile {
  const UpdateCandidateProfile(this.repository, this.access);
  final CandidateRepository repository;
  final AccessPolicy access;
  Future<Candidate> call(ProfileDraft draft) {
    access.require(Permission.viewOwnProfile);
    return repository.update(draft);
  }
}

final class VerifyCandidateByFsp {
  const VerifyCandidateByFsp(this.repository, this.access);
  final CandidateRepository repository;
  final AccessPolicy access;
  Future<Candidate> call() {
    access.require(Permission.viewOwnProfile);
    return repository.syncFsp();
  }
}

final class GetDictionaries {
  const GetDictionaries(this.repository);
  final CandidateRepository repository;
  Future<Dictionaries> call() => repository.dictionaries();
}
