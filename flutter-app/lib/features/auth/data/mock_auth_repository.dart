import '../../../core/di/demo_store.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../admin/domain/admin.dart';
import '../../candidates/domain/candidates.dart';
import '../domain/auth.dart';

final class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.store);
  final DemoStore store;
  Session? _current;
  @override
  Session? get current => _current;
  @override
  Future<Session?> restore() async => _current;
  @override
  Future<Session> login(Email email, String password) async {
    final account = store.users
        .where((entry) => entry.user.email.value == email.value)
        .firstOrNull;
    if (account == null ||
        password != store.passwords[email.value] ||
        account.blocked) {
      throw const AppFailure(
        FailureKind.unauthenticated,
        'invalid_credentials',
      );
    }
    return _current = Session(account.user, isDemo: true);
  }

  @override
  Future<Session> register(Registration r) async {
    if (store.users.any((entry) => entry.user.email.value == r.email.value)) {
      throw const AppFailure(FailureKind.conflict, 'email_already_registered');
    }
    final user = User(
      id: store.nextId(),
      email: r.email,
      name: r.name.trim(),
      role: r.role,
      company: r.company,
    );
    store.users.add(AdminUser(user));
    store.passwords[r.email.value] = r.password;
    if (r.role == Role.candidate) {
      store.candidates.add(
        Candidate(id: user.id, name: user.name, headline: 'IT specialist'),
      );
    }
    return _current = Session(user, isDemo: true);
  }

  @override
  Future<void> logout() async {
    _current = null;
  }

  @override
  Future<void> expire() => logout();
  EntityId get profileId => current!.user.id == DemoStore.id(100)
      ? store.candidates.first.id
      : current!.user.id;
}
