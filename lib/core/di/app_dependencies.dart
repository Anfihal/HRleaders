import 'package:flutter/foundation.dart';

import '../../features/auth/application/auth_use_cases.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/domain/auth.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/candidates/application/candidate_use_cases.dart';
import '../../features/candidates/data/candidate_repository.dart';
import '../../features/candidates/data/mock_candidate_repository.dart';
import '../../features/candidates/domain/candidates.dart';
import '../../features/candidates/presentation/candidate_search_bloc.dart';
import '../../features/candidates/presentation/profile_bloc.dart';
import '../../features/hiring/application/hiring_use_cases.dart';
import '../../features/hiring/data/hiring_repository.dart';
import '../../features/hiring/data/mock_hiring_repository.dart';
import '../../features/hiring/domain/hiring.dart';
import '../../features/hiring/presentation/hiring_blocs.dart';
import '../../features/hiring/presentation/send_offer_bloc.dart';
import '../../features/analytics/application/get_analytics.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../../features/analytics/data/mock_analytics_repository.dart';
import '../../features/analytics/domain/analytics.dart';
import '../../features/admin/application/admin_use_cases.dart';
import '../../features/admin/data/mock_admin_repository.dart';
import '../../features/admin/data/unsupported_admin_repository.dart';
import '../../features/admin/domain/admin.dart';
import '../../features/admin/presentation/users_bloc.dart';
import '../../features/admin/presentation/admin_vacancies_bloc.dart';
import '../../features/security/application/security_use_cases.dart';
import '../../features/security/data/mock_security_repository.dart';
import '../../features/security/data/unsupported_security_repository.dart';
import '../../features/security/domain/security.dart';
import '../../features/security/presentation/notifications_bloc.dart';
import '../../features/messaging/domain/messaging.dart';
import '../../features/messaging/data/messaging_repositories.dart';
import '../../features/messaging/application/get_conversations.dart';
import '../../features/assessments/data/mock_assessment_repository.dart';
import '../../features/assessments/data/remote_assessment_repository.dart';
import '../../features/assessments/domain/assessments.dart';
import '../../features/assessments/presentation/assessment_bloc.dart';
import '../../features/recruiter_assistant/data/mock_recruiter_assistant_repository.dart';
import '../../features/recruiter_assistant/domain/recruiter_assistant.dart';
import '../../features/recruiter_assistant/presentation/assistant_bloc.dart';
import '../../features/recruiter_cjm/data/mock_recruiter_cjm_repository.dart';
import '../../features/recruiter_cjm/data/remote_recruiter_cjm_repository.dart';
import '../../features/recruiter_cjm/domain/recruiter_cjm.dart';
import '../../features/recruiter_cjm/presentation/recruiter_cjm_bloc.dart';
import '../domain/value_objects.dart';
import '../network/api_client.dart';
import '../network/platform_client.dart';
import '../presentation/resource_state.dart';
import '../security/access_policy.dart';
import '../security/token_storage.dart';
import 'demo_store.dart';

final class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.candidates,
    required this.hiring,
    required this.analytics,
    required this.admin,
    required this.security,
    required this.isDemo,
    required this.assessments,
    required this.recruiterAssistant,
    required this.recruiterCjm,
    this.http,
  }) {
    access = AccessPolicy(auth);
    messaging = isDemo
        ? MockMessagingRepository()
        : UnsupportedMessagingRepository();
    authBloc = AuthBloc(
      AuthenticateUser(auth),
      RegisterUser(auth),
      GetCurrentUser(auth),
      EndSession(auth),
    );
    http?.onUnauthorized = () => authBloc.add(const SessionExpired());
  }
  factory AppDependencies.demo() {
    final store = DemoStore();
    final auth = MockAuthRepository(store);
    final assessments = MockAssessmentRepository(store, auth);
    return AppDependencies(
      auth: auth,
      candidates: MockCandidateRepository(store, auth),
      assessments: assessments,
      recruiterAssistant: MockRecruiterAssistantRepository(store),
      recruiterCjm: MockRecruiterCjmRepository(store, auth, assessments),
      hiring: MockHiringRepository(store, auth),
      analytics: MockAnalyticsRepository(store, auth),
      admin: MockAdminRepository(store, auth),
      security: MockSecurityRepository(store, auth),
      isDemo: true,
    );
  }
  factory AppDependencies.remote(Uri baseUri, {bool debugNetwork = false}) {
    final token = TokenHolder();
    final http = HttpApiClient(
      baseUri: baseUri,
      client: createPlatformClient(),
      token: () => token.value,
      trace: kDebugMode && debugNetwork ? debugPrint : null,
    );
    final auth = RemoteAuthRepository(
      AuthApiDataSource(http),
      kIsWeb ? CookieTokenStorage() : NativeTokenStorage(),
      token,
      cookieSession: kIsWeb,
    );
    final assessments = RemoteAssessmentRepository(http, auth);
    return AppDependencies(
      auth: auth,
      candidates: RemoteCandidateRepository(CandidateApiDataSource(http)),
      assessments: assessments,
      recruiterAssistant: const UnsupportedRecruiterAssistantRepository(),
      recruiterCjm: RemoteRecruiterCjmRepository(http, auth, assessments),
      hiring: RemoteHiringRepository(HiringApiDataSource(http)),
      analytics: RemoteAnalyticsRepository(http),
      admin: UnsupportedAdminRepository(),
      security: UnsupportedSecurityRepository(),
      isDemo: false,
      http: http,
    );
  }
  final AuthRepository auth;
  final CandidateRepository candidates;
  final HiringRepository hiring;
  final AnalyticsRepository analytics;
  final AdminRepository admin;
  final SecurityRepository security;
  final bool isDemo;
  final AssessmentRepository assessments;
  final RecruiterAssistantRepository recruiterAssistant;
  final RecruiterCjmRepository recruiterCjm;
  final HttpApiClient? http;
  late final AccessPolicy access;
  late final MessagingRepository messaging;
  late final AuthBloc authBloc;

  CandidateSearchBloc searchBloc() =>
      CandidateSearchBloc(SearchCandidates(candidates, access));
  ProfileBloc profileBloc() => ProfileBloc(
    GetCandidateProfile(candidates, access),
    UpdateCandidateProfile(candidates, access),
    VerifyCandidateByFsp(candidates, access),
  );
  AssessmentBloc assessmentBloc() => AssessmentBloc(assessments);
  RecruiterAssistantBloc recruiterAssistantBloc() =>
      RecruiterAssistantBloc(recruiterAssistant);
  RecruiterCjmBloc recruiterCjmBloc() =>
      RecruiterCjmBloc(recruiterCjm, assessments);
  ResourceBloc<Candidate> detailBloc(EntityId id) =>
      ResourceBloc(() => GetCandidateDetails(candidates, access)(id));
  ResourceBloc<Dictionaries> dictionariesBloc() =>
      ResourceBloc(GetDictionaries(candidates).call);
  VacanciesBloc vacanciesBloc() => VacanciesBloc(
    GetVacancies(hiring, access),
    CreateVacancy(hiring, access),
    CloseVacancy(hiring, access),
  );
  OffersBloc offersBloc({required bool incoming}) => OffersBloc(
    GetOffers(hiring, access),
    RespondToOffer(hiring, access),
    incoming: incoming,
  );
  SendOfferBloc sendOfferBloc() => SendOfferBloc(SendOffer(hiring, access));
  ResourceBloc<List<Match>> matchesBloc({required bool incoming}) =>
      ResourceBloc(
        () => GetMatches(GetOffers(hiring, access))(incoming: incoming),
        isEmpty: (v) => v.isEmpty,
      );
  ResourceBloc<AnalyticsSnapshot> analyticsBloc() =>
      ResourceBloc(GetAnalytics(analytics, access).call);
  ResourceBloc<AdminSnapshot> adminBloc() =>
      ResourceBloc(GetAdminDashboard(admin, access).call);
  UsersBloc usersBloc() =>
      UsersBloc(GetUsers(admin, access), BlockUser(admin, access));
  AdminVacanciesBloc adminVacanciesBloc() => AdminVacanciesBloc(
    GetModeratedVacancies(admin, access),
    ModerateVacancy(admin, access),
  );
  ResourceBloc<GatewaySnapshot> gatewayBloc() =>
      ResourceBloc(GetFspGatewayStatus(admin, access).call);
  ResourceBloc<List<AuditEvent>> auditBloc() =>
      ResourceBloc(GetAuditLog(admin, access).call, isEmpty: (v) => v.isEmpty);
  ResourceBloc<SecuritySnapshot> securityBloc() =>
      ResourceBloc(GetSecurityOverview(security, auth).call);
  NotificationsBloc notificationsBloc() => NotificationsBloc(
    GetNotifications(security, auth),
    MarkNotificationRead(security, auth),
  );
  ResourceBloc<List<Conversation>> messagesBloc() => ResourceBloc(
    GetConversations(messaging, access).call,
    isEmpty: (value) => value.isEmpty,
  );
  Future<void> dispose() async {
    http?.close();
    await authBloc.close();
  }
}
