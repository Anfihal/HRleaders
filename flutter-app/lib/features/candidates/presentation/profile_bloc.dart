import '../../../core/error/app_failure.dart';
import '../../../core/presentation/resource_state.dart';
import '../application/candidate_use_cases.dart';
import '../domain/candidates.dart';

final class ProfileBloc extends ResourceBloc<Candidate> {
  ProfileBloc(GetCandidateProfile get, this.updateProfile, this.verify)
    : super(get.call);
  final UpdateCandidateProfile updateProfile;
  final VerifyCandidateByFsp verify;
  Future<void> save(ProfileDraft draft) => _change(() => updateProfile(draft));
  Future<void> sync() => _change(verify.call);
  Future<void> _change(Future<Candidate> Function() operation) async {
    if (state.busy) return;
    emit(ResourceState(ResourcePhase.saving, value: state.value));
    try {
      final profile = await operation();
      if (!isClosed) {
        emit(ResourceState(ResourcePhase.loaded, value: profile, saved: true));
      }
    } on AppFailure catch (error) {
      if (!isClosed) {
        emit(
          ResourceState(
            ResourcePhase.failure,
            value: state.value,
            failure: error,
          ),
        );
      }
    }
  }
}
