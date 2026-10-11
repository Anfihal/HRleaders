import '../../../core/security/access_policy.dart';
import '../../auth/domain/auth.dart';
import '../domain/messaging.dart';

final class GetConversations {
  const GetConversations(this.repository, this.access);
  final MessagingRepository repository;
  final AccessPolicy access;
  Future<List<Conversation>> call() {
    access.require(Permission.useMessaging);
    return repository.conversations();
  }
}
