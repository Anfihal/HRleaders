import '../../../core/presentation/resource_state.dart';
import '../../../core/domain/value_objects.dart';
import '../../hiring/domain/hiring.dart';
import '../application/admin_use_cases.dart';

class AdminVacanciesBloc extends ResourceBloc<List<Vacancy>> {
  AdminVacanciesBloc(GetModeratedVacancies load, this.moderate)
    : super(load.call, isEmpty: (v) => v.isEmpty);
  final ModerateVacancy moderate;
  Future<void> closeVacancy(EntityId id) => mutate(() => moderate(id));
}
