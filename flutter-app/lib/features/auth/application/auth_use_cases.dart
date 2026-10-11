import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../domain/auth.dart';

final class AuthenticateUser {
  const AuthenticateUser(this.repository);
  final AuthRepository repository;
  Future<Session> call(String email, String password) {
    if (password.isEmpty || password.length > 128) {
      throw const AppFailure(FailureKind.validation, 'invalid_password');
    }
    return repository.login(Email(email), password);
  }
}

final class RegisterUser {
  const RegisterUser(this.repository);
  final AuthRepository repository;
  Future<Session> call(Registration request) {
    if (request.name.trim().length < 2 ||
        request.password.length < 8 ||
        !RegExp(r'[0-9]').hasMatch(request.password) ||
        !RegExp(r'[a-zA-Zа-яА-Я]').hasMatch(request.password)) {
      throw const AppFailure(FailureKind.validation, 'invalid_registration');
    }
    if (request.role != Role.candidate && request.role != Role.hr) {
      throw const AppFailure(
        FailureKind.forbidden,
        'unsupported_registration_role',
      );
    }
    if (request.role == Role.hr && (request.company?.trim().isEmpty ?? true)) {
      throw const AppFailure(FailureKind.validation, 'company_name_required');
    }
    return repository.register(request);
  }
}

final class GetCurrentUser {
  const GetCurrentUser(this.repository);
  final AuthRepository repository;
  Future<Session?> call() => repository.restore();
}

final class EndSession {
  const EndSession(this.repository);
  final AuthRepository repository;
  Future<void> call({bool expired = false}) =>
      expired ? repository.expire() : repository.logout();
}
