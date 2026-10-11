import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../features/auth/domain/auth.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/candidates/presentation/candidate_detail_page.dart';
import '../../features/candidates/presentation/candidate_search_bloc.dart';
import '../../features/candidates/presentation/candidate_search_page.dart';
import '../../features/candidates/presentation/profile_page.dart';
import '../../features/employers/presentation/employer_home_page.dart';
import '../../features/employers/presentation/company_page.dart';
import '../../features/messaging/presentation/messages_page.dart';
import '../../features/hiring/presentation/matches_page.dart';
import '../../features/hiring/presentation/offers_page.dart';
import '../../features/hiring/presentation/vacancies_page.dart';
import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/admin/presentation/users_page.dart';
import '../../features/admin/presentation/admin_vacancies_page.dart';
import '../../features/admin/presentation/gateway_page.dart';
import '../../features/admin/presentation/audit_page.dart';
import '../../features/security/presentation/security_pages.dart';
import '../../features/landing/presentation/landing_page.dart';
import '../../features/assessments/presentation/assessment_pages.dart';
import '../../features/recruiter_assistant/presentation/recruiter_assistant_page.dart';
import '../../features/recruiter_cjm/presentation/recruiter_cjm_pages.dart';
import '../components/app_shell.dart';
import '../components/app_components.dart';
import '../di/app_dependencies.dart';
import '../domain/value_objects.dart';
import '../error/app_failure.dart';
import '../localization/localization.dart';
import '../theme/settings_page.dart';
import 'destinations.dart';
import 'route_policy.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

GoRouter createAppRouter(
  AppDependencies deps,
  AuthRouterRefresh refresh, {
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: refresh,
  redirect: (_, state) => routeRedirect(
    state.uri,
    deps.auth.current?.user,
    restoring: deps.authBloc.state.phase == AuthPhase.initial,
  ),
  errorBuilder: (_, _) => const RouteErrorPage(),
  routes: [
    GoRoute(path: '/', builder: (_, _) => const LandingPage()),
    GoRoute(
      path: '/boot',
      builder: (_, _) =>
          const m.Scaffold(body: Center(child: AppLoadingState())),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const m.Scaffold(body: SafeArea(child: LoginPage())),
    ),
    GoRoute(
      path: '/register',
      builder: (_, state) => m.Scaffold(
        body: SafeArea(
          child: LoginPage(
            register: true,
            initialRole: state.uri.queryParameters['role'] == 'hr'
                ? Role.hr
                : Role.candidate,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/forbidden',
      builder: (_, _) => const RouteErrorPage(forbidden: true),
    ),
    ShellRoute(
      builder: (_, _, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/candidate',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.offersBloc(incoming: true)..load(),
            child: const OffersPage(),
          ),
        ),
        GoRoute(
          path: '/candidate/profile',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => deps.profileBloc()..load()),
              BlocProvider(create: (_) => deps.assessmentBloc()..load()),
              BlocProvider(create: (_) => deps.recruiterCjmBloc()..load()),
            ],
            child: const ProfilePage(),
          ),
        ),
        GoRoute(
          path: '/candidate/assessments',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => deps.assessmentBloc()..load()),
              BlocProvider(create: (_) => deps.recruiterCjmBloc()..load()),
            ],
            child: const AssessmentsPage(),
          ),
        ),
        GoRoute(
          path: '/candidate/assessments/:attemptId/report',
          builder: (_, state) => BlocProvider(
            create: (_) => deps.assessmentBloc(),
            child: AssessmentReportPage(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
        ),
        GoRoute(
          path: '/candidate/assessments/:attemptId/reflection',
          builder: (_, state) => BlocProvider(
            create: (_) => deps.assessmentBloc(),
            child: AssessmentReflectionPage(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
        ),
        GoRoute(
          path: '/candidate/assessments/:attemptId',
          builder: (_, state) => BlocProvider(
            create: (_) => deps.assessmentBloc(),
            child: AssessmentAttemptPage(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
        ),
        GoRoute(
          path: '/candidate/offers',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.offersBloc(incoming: true)..load(),
            child: const OffersPage(),
          ),
        ),
        GoRoute(
          path: '/candidate/matches',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.matchesBloc(incoming: true)..load(),
            child: const MatchesPage(),
          ),
        ),
        GoRoute(path: '/employer', builder: (_, _) => const EmployerHomePage()),
        GoRoute(
          path: '/employer/assistant',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.recruiterAssistantBloc()..load(),
            child: const RecruiterAssistantPage(),
          ),
        ),
        GoRoute(
          path: '/employer/tracking',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.recruiterCjmBloc()..load(),
            child: const RecruiterTrackingPage(),
          ),
        ),
        GoRoute(
          path: '/employer/company',
          builder: (_, _) => const CompanyPage(),
        ),
        GoRoute(
          path: '/messages',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.messagesBloc()..load(),
            child: const MessagesPage(),
          ),
        ),
        GoRoute(
          path: '/employer/candidates',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => deps.searchBloc()..add(const SearchRequested()),
              ),
              BlocProvider(create: (_) => deps.dictionariesBloc()..load()),
            ],
            child: const CandidateSearchPage(),
          ),
        ),
        GoRoute(
          path: '/employer/candidates/:id',
          builder: (_, state) {
            try {
              final id = EntityId(state.pathParameters['id']!);
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => deps.detailBloc(id)..load()),
                  BlocProvider(create: (_) => deps.recruiterCjmBloc()..load()),
                ],
                child: const CandidateDetailPage(),
              );
            } on AppFailure {
              return const RouteErrorPage();
            }
          },
        ),
        GoRoute(
          path: '/employer/vacancies',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.vacanciesBloc()..load(),
            child: const VacanciesPage(),
          ),
        ),
        GoRoute(
          path: '/employer/offers',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.offersBloc(incoming: false)..load(),
            child: const OffersPage(),
          ),
        ),
        GoRoute(
          path: '/employer/matches',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.matchesBloc(incoming: false)..load(),
            child: const MatchesPage(),
          ),
        ),
        GoRoute(
          path: '/employer/analytics',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.analyticsBloc()..load(),
            child: const AnalyticsPage(),
          ),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.adminBloc()..load(),
            child: const AdminPage(),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.usersBloc()..load(),
            child: const UsersPage(),
          ),
        ),
        GoRoute(
          path: '/admin/vacancies',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.adminVacanciesBloc()..load(),
            child: const AdminVacanciesPage(),
          ),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.adminBloc()..load(),
            child: const AdminPage(promotion: true),
          ),
        ),
        GoRoute(
          path: '/admin/fsp',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.gatewayBloc()..load(),
            child: const GatewayPage(),
          ),
        ),
        GoRoute(
          path: '/admin/audit',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.auditBloc()..load(),
            child: const AuditPage(),
          ),
        ),
        GoRoute(
          path: '/security',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.securityBloc()..load(),
            child: const SecurityPage(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => BlocProvider(
            create: (_) => deps.notificationsBloc()..load(),
            child: const NotificationsPage(),
          ),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        GoRoute(
          path: '/offer/:id',
          builder: (_, state) {
            try {
              final id = EntityId(state.pathParameters['id']!);
              return BlocProvider(
                create: (_) => deps.offersBloc(
                  incoming: deps.auth.current!.user.can(
                    Permission.respondOffers,
                  ),
                )..load(),
                child: OffersPage(focusId: id),
              );
            } on AppFailure {
              return const RouteErrorPage();
            }
          },
        ),
      ],
    ),
  ],
);

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key, this.forbidden = false});
  final bool forbidden;
  @override
  Widget build(BuildContext context) => m.Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(forbidden ? context.l.forbidden : context.l.notFound),
              const SizedBox(height: 24),
              AppButton(
                label: context.l.home,
                onPressed: () {
                  final user = context
                      .read<AppDependencies>()
                      .auth
                      .current
                      ?.user;
                  context.go(user == null ? '/' : homeFor(user));
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
