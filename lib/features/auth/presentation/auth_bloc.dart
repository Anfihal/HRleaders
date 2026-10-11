import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../application/auth_use_cases.dart';
import '../domain/auth.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class RestoreSession extends AuthEvent {
  const RestoreSession();
}

final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted(this.email, this.password);
  final String email;
  final String password;
}

final class RegistrationSubmitted extends AuthEvent {
  const RegistrationSubmitted(this.registration);
  final Registration registration;
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

final class SessionExpired extends AuthEvent {
  const SessionExpired();
}

enum AuthPhase { initial, loading, authenticated, anonymous, failure }

final class AuthState {
  const AuthState(this.phase, {this.session, this.failure});
  final AuthPhase phase;
  final Session? session;
  final AppFailure? failure;
}

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authenticate, this.register, this.restore, this.end)
    : super(const AuthState(AuthPhase.initial)) {
    on<AuthEvent>(_handle, transformer: sequential());
  }
  final AuthenticateUser authenticate;
  final RegisterUser register;
  final GetCurrentUser restore;
  final EndSession end;
  Future<void> _handle(AuthEvent event, Emitter<AuthState> emit) async {
    emit(const AuthState(AuthPhase.loading));
    try {
      final session = switch (event) {
        RestoreSession() => await restore(),
        LoginSubmitted() => await authenticate(event.email, event.password),
        RegistrationSubmitted() => await register(event.registration),
        LogoutRequested() || SessionExpired() => null,
      };
      if (event is LogoutRequested || event is SessionExpired) {
        await end(expired: event is SessionExpired);
      }
      emit(
        AuthState(
          session == null ? AuthPhase.anonymous : AuthPhase.authenticated,
          session: session,
        ),
      );
    } on AppFailure catch (error) {
      emit(AuthState(AuthPhase.failure, failure: error));
    }
  }
}
