import '../../../core/domain/value_objects.dart';

enum RecruiterMessageRole { user, assistant }

final class RecruiterMessage {
  const RecruiterMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.demonstration = false,
  });

  final EntityId id;
  final RecruiterMessageRole role;
  final String text;
  final DateTime createdAt;
  final bool demonstration;
}

abstract interface class RecruiterAssistantRepository {
  Future<List<RecruiterMessage>> history();
  Future<RecruiterMessage> ask(String prompt);
  Future<void> clear();
}
