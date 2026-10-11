import '../../../core/presentation/resource_state.dart';
import '../application/security_use_cases.dart';
import '../domain/security.dart';

final class NotificationsBloc extends ResourceBloc<List<AppNotification>> {
  NotificationsBloc(GetNotifications get, this.markRead)
    : super(get.call, isEmpty: (v) => v.isEmpty);
  final MarkNotificationRead markRead;
  Future<void> read(String id) => mutate(() => markRead(id));
}
