import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/security/token_storage.dart';
import '../domain/auth.dart';

final class UserDto {
  UserDto(Object? json) : _json = JsonReader(json);
  final JsonReader _json;
  User toDomain() => User(
    id: EntityId(_json.string('id')),
    email: Email(_json.string('email')),
    name: _json.string('full_name'),
    company: _json.optionalString('company_name'),
    role: switch (_json.string('role')) {
      'candidate' => Role.candidate,
      'employer' => Role.hr,
      _ => throw const AppFailure(
        FailureKind.malformed,
        'unsupported_server_role',
      ),
    },
  );
}

final class AuthApiDataSource {
  const AuthApiDataSource(this.api);
  final ApiClient api;
  Future<JsonReader> login(Email email, String password) async => JsonReader(
    await api.request(
      'POST',
      'auth/login',
      body: {'email': email.value, 'password': password},
    ),
  );
  Future<JsonReader> register(Registration r) async => JsonReader(
    await api.request(
      'POST',
      'auth/register',
      body: {
        'email': r.email.value,
        'password': r.password,
        'full_name': r.name.trim(),
        'role': r.role == Role.hr ? 'employer' : 'candidate',
        'company_name': r.company,
      },
    ),
  );
  Future<User> me() async =>
      UserDto(await api.request('GET', 'auth/me')).toDomain();
  Future<void> logout() async {
    await api.request('POST', 'auth/logout');
  }
}

final class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(
    this.source,
    this.storage,
    this.token, {
    required this.cookieSession,
  });
  final AuthApiDataSource source;
  final TokenStorage storage;
  final TokenHolder token;
  final bool cookieSession;
  Session? _current;
  @override
  Session? get current => _current;
  @override
  Future<Session?> restore() async {
    token.value = await storage.read();
    if (!cookieSession && token.value == null) return null;
    try {
      return _current = Session(await source.me());
    } on AppFailure catch (error) {
      if (error.kind != FailureKind.unauthenticated) rethrow;
      await expire();
      return null;
    }
  }

  Future<Session> _start(JsonReader response) async {
    final session = Session(UserDto(response.data['user']).toDomain());
    if (!cookieSession) {
      final value = response.string('access_token');
      await storage.write(value);
      token.value = value;
    }
    return _current = session;
  }

  @override
  Future<Session> login(Email email, String password) async =>
      _start(await source.login(email, password));
  @override
  Future<Session> register(Registration registration) async =>
      _start(await source.register(registration));
  @override
  Future<void> logout() async {
    try {
      await source.logout();
    } finally {
      await expire();
    }
  }

  @override
  Future<void> expire() async {
    _current = null;
    token.value = null;
    await storage.clear();
  }
}
