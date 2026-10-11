import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/features/messaging/application/get_conversations.dart';
import 'package:hrleaders/features/messaging/data/messaging_repositories.dart';

void main() {
  test('messaging enforces identity and never invents live chat', () async {
    final deps = AppDependencies.demo();
    addTearDown(deps.dispose);
    final get = GetConversations(deps.messaging, deps.access);
    expect(() => get(), throwsA(isA<AppFailure>()));
    await deps.auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
    expect(await get(), isEmpty);
    expect(deps.auth.current!.user.company, isNotEmpty);
    await expectLater(
      GetConversations(UnsupportedMessagingRepository(), deps.access)(),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unsupported,
        ),
      ),
    );
  });
}
