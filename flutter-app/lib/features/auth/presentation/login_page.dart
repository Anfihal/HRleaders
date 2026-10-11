import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth.dart';
import 'auth_bloc.dart';
import 'candidate_flag_game.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.register = false,
    this.initialRole = Role.candidate,
  });
  final bool register;
  final Role initialRole;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _company = TextEditingController();
  late Role _role = widget.initialRole;
  AppFailure? _failure;
  bool _gameExpanded = false;
  @override
  void dispose() {
    for (final c in [_email, _password, _name, _company]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() => _failure = null);
    try {
      context.read<AuthBloc>().add(
        widget.register
            ? RegistrationSubmitted(
                Registration(
                  email: Email(_email.text),
                  password: _password.text,
                  name: _name.text,
                  role: _role,
                  company: _company.text,
                ),
              )
            : LoginSubmitted(_email.text, _password.text),
      );
    } on AppFailure catch (error) {
      setState(() => _failure = error);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final busy = state.phase == AuthPhase.loading;
            final error = _failure ?? state.failure;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBackButton(onPressed: () => context.go('/')),
                const SizedBox(height: AppSpacing.section),
                AppSectionHeader(
                  title: widget.register ? context.l.register : context.l.login,
                  subtitle: context.l.tagline,
                ),
                if (widget.register) ...[
                  AppTextField(
                    label: context.l.fullName,
                    controller: _name,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  AppSelect<Role>(
                    label: context.l.role,
                    value: _role,
                    options: {
                      Role.candidate: context.l.candidate,
                      Role.hr: context.l.employer,
                    },
                    onChanged: (v) =>
                        setState(() => _role = v ?? Role.candidate),
                  ),
                  const SizedBox(height: 16),
                  if (_role == Role.hr) ...[
                    AppTextField(
                      label: context.l.company,
                      controller: _company,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                AppTextField(
                  label: context.l.email,
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: context.l.password,
                  controller: _password,
                  obscure: true,
                  enabled: !busy,
                  onSubmitted: (_) {
                    if (!busy) _submit();
                  },
                ),
                if (widget.register)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(context.l.registrationHint),
                  ),
                if (widget.register) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    label: _gameExpanded
                        ? context.l.closeCandidateGame
                        : context.l.openCandidateGame,
                    secondary: true,
                    icon: m.Icons.sports_esports,
                    onPressed: () =>
                        setState(() => _gameExpanded = !_gameExpanded),
                  ),
                  if (_gameExpanded) ...[
                    const SizedBox(height: 12),
                    const CandidateFlagGame(),
                  ],
                ],
                const SizedBox(height: 24),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(context.failureLabel(error)),
                    ),
                  ),
                AppButton(
                  label: widget.register ? context.l.register : context.l.login,
                  onPressed: _submit,
                  busy: busy,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: widget.register ? context.l.login : context.l.register,
                  secondary: true,
                  onPressed: () =>
                      context.go(widget.register ? '/login' : '/register'),
                ),
                if (context.read<AppDependencies>().isDemo) ...[
                  const SizedBox(height: 32),
                  Text(context.l.demoAccounts),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Role.values
                        .map(
                          (role) => AppButton(
                            label: context.roleLabel(role),
                            secondary: true,
                            onPressed: busy
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    LoginSubmitted(
                                      '${role.name}@demo.hrleaders.example',
                                      'Demo12345',
                                    ),
                                  ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.l.demoHelp),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}
