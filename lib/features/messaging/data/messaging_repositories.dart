import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../domain/messaging.dart';

class UnsupportedMessagingRepository implements MessagingRepository {
  Never _unsupported() => throw const AppFailure(
    FailureKind.unsupported,
    'messaging_contract_unavailable',
  );
  @override
  Future<List<Conversation>> conversations() async => _unsupported();
  @override
  Future<List<ChatMessage>> messages(EntityId conversation) async =>
      _unsupported();
  @override
  Future<void> send(EntityId conversation, String text) async => _unsupported();
}

/// Empty fictional inbox. Sending remains unavailable until a chat contract exists.
final class MockMessagingRepository extends UnsupportedMessagingRepository {
  @override
  Future<List<Conversation>> conversations() async => const [];
}
