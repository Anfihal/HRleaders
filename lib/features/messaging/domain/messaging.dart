import '../../../core/domain/value_objects.dart';

final class Conversation {
  const Conversation({required this.id, required this.participants});
  final EntityId id;
  final List<EntityId> participants;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
  });
  final EntityId id;
  final EntityId sender;
  final String text;
  final DateTime sentAt;
}

/// Future contract boundary; no chat endpoint exists in the current API.
abstract interface class MessagingRepository {
  Future<List<Conversation>> conversations();
  Future<List<ChatMessage>> messages(EntityId conversation);
  Future<void> send(EntityId conversation, String text);
}
