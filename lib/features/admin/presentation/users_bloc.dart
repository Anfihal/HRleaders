import '../../../core/domain/value_objects.dart';
import '../../../core/presentation/resource_state.dart';
import '../application/admin_use_cases.dart';
import '../domain/admin.dart';

final class UsersBloc extends ResourceBloc<List<AdminUser>> {
  UsersBloc(GetUsers get, this.blockUser)
    : super(get.call, isEmpty: (v) => v.isEmpty);
  final BlockUser blockUser;
  Future<void> block(EntityId id, bool blocked) =>
      mutate(() => blockUser(id, blocked));
}
