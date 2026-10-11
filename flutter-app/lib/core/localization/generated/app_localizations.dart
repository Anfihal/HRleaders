import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HRleaders'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Skills verified. People connected.'**
  String get tagline;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Once a battle.\nNow a connection.'**
  String get heroTitle;

  /// No description provided for @heroBody.
  ///
  /// In en, this message translates to:
  /// **'Employers find FSP-verified specialists. Candidates receive relevant offers with a concrete salary.'**
  String get heroBody;

  /// No description provided for @candidateCta.
  ///
  /// In en, this message translates to:
  /// **'I\'m a candidate'**
  String get candidateCta;

  /// No description provided for @employerCta.
  ///
  /// In en, this message translates to:
  /// **'I\'m an employer'**
  String get employerCta;

  /// No description provided for @fight.
  ///
  /// In en, this message translates to:
  /// **'01 / FIGHT'**
  String get fight;

  /// No description provided for @fightBody.
  ///
  /// In en, this message translates to:
  /// **'Endless applications. Unanswered messages. Skills lost behind a résumé.'**
  String get fightBody;

  /// No description provided for @tap.
  ///
  /// In en, this message translates to:
  /// **'02 / TAP'**
  String get tap;

  /// No description provided for @tapBody.
  ///
  /// In en, this message translates to:
  /// **'A verified profile connects the right specialist with the right employer.'**
  String get tapBody;

  /// No description provided for @hug.
  ///
  /// In en, this message translates to:
  /// **'05 / HUG'**
  String get hug;

  /// No description provided for @hugBody.
  ///
  /// In en, this message translates to:
  /// **'A concrete offer. A clear decision. A match built on trust.'**
  String get hugBody;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Hiring is a meeting.'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Sports programming turns practical skills into evidence. Reverse hiring turns that evidence into a human connection.'**
  String get aboutBody;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'The people behind the connection'**
  String get team;

  /// No description provided for @dmitry.
  ///
  /// In en, this message translates to:
  /// **'Dmitry'**
  String get dmitry;

  /// No description provided for @anfisa.
  ///
  /// In en, this message translates to:
  /// **'Anfisa'**
  String get anfisa;

  /// No description provided for @artem.
  ///
  /// In en, this message translates to:
  /// **'Artyom'**
  String get artem;

  /// No description provided for @cto.
  ///
  /// In en, this message translates to:
  /// **'CTO'**
  String get cto;

  /// No description provided for @fspLead.
  ///
  /// In en, this message translates to:
  /// **'Head of FSP Integration'**
  String get fspLead;

  /// No description provided for @productLead.
  ///
  /// In en, this message translates to:
  /// **'Product Lead'**
  String get productLead;

  /// No description provided for @teamEngineering.
  ///
  /// In en, this message translates to:
  /// **'Clear contracts. Reliable systems.'**
  String get teamEngineering;

  /// No description provided for @teamVerification.
  ///
  /// In en, this message translates to:
  /// **'Achievements deserve to be recognized.'**
  String get teamVerification;

  /// No description provided for @teamProduct.
  ///
  /// In en, this message translates to:
  /// **'Every offer starts with a person.'**
  String get teamProduct;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Protecting data. Building trust.'**
  String get securityTitle;

  /// No description provided for @securityBody.
  ///
  /// In en, this message translates to:
  /// **'The architecture supports secure transport, HttpOnly web sessions, role-based access and the FSP gateway. Deployment and organizational measures are required for personal-data compliance.'**
  String get securityBody;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demonstration · fictional data'**
  String get demo;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Connected to HRleaders API'**
  String get live;

  /// No description provided for @demoHelp.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts share in-memory data until the app reloads. Verification and administrative metrics are simulated.'**
  String get demoHelp;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @candidate.
  ///
  /// In en, this message translates to:
  /// **'Candidate'**
  String get candidate;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer / HR'**
  String get employer;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @analyst.
  ///
  /// In en, this message translates to:
  /// **'Analyst'**
  String get analyst;

  /// No description provided for @superadmin.
  ///
  /// In en, this message translates to:
  /// **'Superadmin'**
  String get superadmin;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Explore a demo account'**
  String get demoAccounts;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profile;

  /// No description provided for @candidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidates;

  /// No description provided for @vacancies.
  ///
  /// In en, this message translates to:
  /// **'Vacancies'**
  String get vacancies;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @fsp.
  ///
  /// In en, this message translates to:
  /// **'FSP integration'**
  String get fsp;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @audit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get audit;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get menu;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search candidates'**
  String get search;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @discipline.
  ///
  /// In en, this message translates to:
  /// **'FSP discipline'**
  String get discipline;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Verification level'**
  String get level;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @workFormat.
  ///
  /// In en, this message translates to:
  /// **'Work format'**
  String get workFormat;

  /// No description provided for @teamRole.
  ///
  /// In en, this message translates to:
  /// **'Team role'**
  String get teamRole;

  /// No description provided for @skill.
  ///
  /// In en, this message translates to:
  /// **'Skill / stack'**
  String get skill;

  /// No description provided for @maxSalary.
  ///
  /// In en, this message translates to:
  /// **'Maximum salary, RUB'**
  String get maxSalary;

  /// No description provided for @verifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'FSP verified only'**
  String get verifiedOnly;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified by FSP'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Awaiting FSP verification'**
  String get unverified;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get nextPage;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get empty;

  /// No description provided for @emptyCandidates.
  ///
  /// In en, this message translates to:
  /// **'No candidates match these filters'**
  String get emptyCandidates;

  /// No description provided for @emptyOffers.
  ///
  /// In en, this message translates to:
  /// **'Your next connection will appear here'**
  String get emptyOffers;

  /// No description provided for @emptyMatches.
  ///
  /// In en, this message translates to:
  /// **'Accepted offers become matches'**
  String get emptyMatches;

  /// No description provided for @noSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary to be discussed'**
  String get noSalary;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @headline.
  ///
  /// In en, this message translates to:
  /// **'Professional headline'**
  String get headline;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City / region'**
  String get city;

  /// No description provided for @salaryExpectation.
  ///
  /// In en, this message translates to:
  /// **'Expected salary, RUB'**
  String get salaryExpectation;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get skills;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get about;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Open to offers'**
  String get availability;

  /// No description provided for @fspId.
  ///
  /// In en, this message translates to:
  /// **'FSP participant ID'**
  String get fspId;

  /// No description provided for @syncFsp.
  ///
  /// In en, this message translates to:
  /// **'Verify with FSP'**
  String get syncFsp;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last verification'**
  String get lastSync;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Verified categories'**
  String get categories;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saved;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send an offer'**
  String get sendOffer;

  /// No description provided for @offerMessage.
  ///
  /// In en, this message translates to:
  /// **'Personal message'**
  String get offerMessage;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary, RUB'**
  String get salary;

  /// No description provided for @salaryFrom.
  ///
  /// In en, this message translates to:
  /// **'Salary from, RUB'**
  String get salaryFrom;

  /// No description provided for @salaryTo.
  ///
  /// In en, this message translates to:
  /// **'Salary to, RUB'**
  String get salaryTo;

  /// No description provided for @vacancyTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacancy title'**
  String get vacancyTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @createVacancy.
  ///
  /// In en, this message translates to:
  /// **'Publish vacancy'**
  String get createVacancy;

  /// No description provided for @closeVacancy.
  ///
  /// In en, this message translates to:
  /// **'Close vacancy'**
  String get closeVacancy;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @viewOffer.
  ///
  /// In en, this message translates to:
  /// **'View offer'**
  String get viewOffer;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline offer'**
  String get decline;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw offer'**
  String get withdraw;

  /// No description provided for @declineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for declining'**
  String get declineReason;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent'**
  String get sent;

  /// No description provided for @viewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get viewed;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted · match'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'A connection made.'**
  String get matchTitle;

  /// No description provided for @incomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s already interested in you?'**
  String get incomingTitle;

  /// No description provided for @employerTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a person. Start a conversation.'**
  String get employerTitle;

  /// No description provided for @employerBody.
  ///
  /// In en, this message translates to:
  /// **'Search verified categories, review achievements and send a personal offer with a salary.'**
  String get employerBody;

  /// No description provided for @funnel.
  ///
  /// In en, this message translates to:
  /// **'Hiring funnel'**
  String get funnel;

  /// No description provided for @pool.
  ///
  /// In en, this message translates to:
  /// **'Candidate pool'**
  String get pool;

  /// No description provided for @verifiedCount.
  ///
  /// In en, this message translates to:
  /// **'Verified candidates'**
  String get verifiedCount;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Profile views'**
  String get views;

  /// No description provided for @offersSent.
  ///
  /// In en, this message translates to:
  /// **'Offers sent'**
  String get offersSent;

  /// No description provided for @offersOpened.
  ///
  /// In en, this message translates to:
  /// **'Offers viewed'**
  String get offersOpened;

  /// No description provided for @offersAccepted.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get offersAccepted;

  /// No description provided for @acceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance rate'**
  String get acceptance;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Average response time (hours)'**
  String get responseTime;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @unsupported.
  ///
  /// In en, this message translates to:
  /// **'This service is awaiting an API contract. No live data is available.'**
  String get unsupported;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'A view of the whole system'**
  String get adminTitle;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion analytics'**
  String get promotion;

  /// No description provided for @regions.
  ///
  /// In en, this message translates to:
  /// **'Regions'**
  String get regions;

  /// No description provided for @registeredUsers.
  ///
  /// In en, this message translates to:
  /// **'Registered users'**
  String get registeredUsers;

  /// No description provided for @activeVacancies.
  ///
  /// In en, this message translates to:
  /// **'Active vacancies'**
  String get activeVacancies;

  /// No description provided for @verificationRate.
  ///
  /// In en, this message translates to:
  /// **'Verification rate'**
  String get verificationRate;

  /// No description provided for @timeToMatch.
  ///
  /// In en, this message translates to:
  /// **'Average time to match (hours)'**
  String get timeToMatch;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get unblock;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway status'**
  String get gateway;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @degraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get degraded;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get queue;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @latency.
  ///
  /// In en, this message translates to:
  /// **'Latency (ms)'**
  String get latency;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get sessions;

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get currentSession;

  /// No description provided for @loginHistory.
  ///
  /// In en, this message translates to:
  /// **'Login history'**
  String get loginHistory;

  /// No description provided for @twoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactor;

  /// No description provided for @twoFactorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication requires a backend integration.'**
  String get twoFactorUnavailable;

  /// No description provided for @securityEvents.
  ///
  /// In en, this message translates to:
  /// **'Security events'**
  String get securityEvents;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markRead;

  /// No description provided for @offerReceived.
  ///
  /// In en, this message translates to:
  /// **'Offer received'**
  String get offerReceived;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get offerRejected;

  /// No description provided for @matchCreated.
  ///
  /// In en, this message translates to:
  /// **'Match created'**
  String get matchCreated;

  /// No description provided for @verificationCompleted.
  ///
  /// In en, this message translates to:
  /// **'FSP verification completed'**
  String get verificationCompleted;

  /// No description provided for @securityAlert.
  ///
  /// In en, this message translates to:
  /// **'Security alert'**
  String get securityAlert;

  /// No description provided for @invalidForm.
  ///
  /// In en, this message translates to:
  /// **'Check the fields and try again'**
  String get invalidForm;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Check your email and password'**
  String get invalidCredentials;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get sessionExpired;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Your role does not have access to this page'**
  String get forbidden;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'This item could not be found'**
  String get notFound;

  /// No description provided for @conflict.
  ///
  /// In en, this message translates to:
  /// **'This item has changed. Refresh and try again.'**
  String get conflict;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and retry.'**
  String get networkError;

  /// No description provided for @malformed.
  ///
  /// In en, this message translates to:
  /// **'The service returned an unexpected response'**
  String get malformed;

  /// No description provided for @junior.
  ///
  /// In en, this message translates to:
  /// **'Junior'**
  String get junior;

  /// No description provided for @middle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get middle;

  /// No description provided for @senior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get senior;

  /// No description provided for @lead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get lead;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @algorithmic.
  ///
  /// In en, this message translates to:
  /// **'Algorithmic programming'**
  String get algorithmic;

  /// No description provided for @productProgramming.
  ///
  /// In en, this message translates to:
  /// **'Product programming'**
  String get productProgramming;

  /// No description provided for @securityProgramming.
  ///
  /// In en, this message translates to:
  /// **'Security programming'**
  String get securityProgramming;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Points to the next level'**
  String get nextLevel;

  /// No description provided for @trust.
  ///
  /// In en, this message translates to:
  /// **'Verification → visibility → offer → match'**
  String get trust;

  /// No description provided for @regionMoscow.
  ///
  /// In en, this message translates to:
  /// **'Moscow'**
  String get regionMoscow;

  /// No description provided for @regionPetersburg.
  ///
  /// In en, this message translates to:
  /// **'Saint Petersburg'**
  String get regionPetersburg;

  /// No description provided for @regionKazan.
  ///
  /// In en, this message translates to:
  /// **'Kazan'**
  String get regionKazan;

  /// No description provided for @regionNovosibirsk.
  ///
  /// In en, this message translates to:
  /// **'Novosibirsk'**
  String get regionNovosibirsk;

  /// No description provided for @demoAudit.
  ///
  /// In en, this message translates to:
  /// **'Demo role access checked'**
  String get demoAudit;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Session credentials stay in HttpOnly cookies on web and OS secure storage on native devices.'**
  String get privacy;

  /// No description provided for @registrationHint.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with a letter and a digit. The server applies its configured policy.'**
  String get registrationHint;

  /// No description provided for @networkStage.
  ///
  /// In en, this message translates to:
  /// **'03 / NETWORK'**
  String get networkStage;

  /// No description provided for @networkBody.
  ///
  /// In en, this message translates to:
  /// **'Verified achievements make specialists visible to employers.'**
  String get networkBody;

  /// No description provided for @connectionStage.
  ///
  /// In en, this message translates to:
  /// **'04 / CONNECTION'**
  String get connectionStage;

  /// No description provided for @connectionBody.
  ///
  /// In en, this message translates to:
  /// **'An employer finds relevant skills and starts a personal conversation.'**
  String get connectionBody;

  /// No description provided for @trustStage.
  ///
  /// In en, this message translates to:
  /// **'06 / TRUST'**
  String get trustStage;

  /// No description provided for @trustBody.
  ///
  /// In en, this message translates to:
  /// **'FSP evidence, a real vacancy and a concrete salary make the decision clear.'**
  String get trustBody;

  /// No description provided for @matchStage.
  ///
  /// In en, this message translates to:
  /// **'07 / MATCH'**
  String get matchStage;

  /// No description provided for @matchBody.
  ///
  /// In en, this message translates to:
  /// **'The candidate accepts. Both people see the same match and can plan their next meeting.'**
  String get matchBody;

  /// No description provided for @robotics.
  ///
  /// In en, this message translates to:
  /// **'Robotics'**
  String get robotics;

  /// No description provided for @uav.
  ///
  /// In en, this message translates to:
  /// **'Unmanned aircraft systems'**
  String get uav;

  /// No description provided for @levelBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get levelBasic;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelExpert;

  /// No description provided for @resultWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get resultWinner;

  /// No description provided for @resultPrizeWinner.
  ///
  /// In en, this message translates to:
  /// **'Prize winner'**
  String get resultPrizeWinner;

  /// No description provided for @resultFinalist.
  ///
  /// In en, this message translates to:
  /// **'Finalist'**
  String get resultFinalist;

  /// No description provided for @resultParticipant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get resultParticipant;

  /// No description provided for @resultFirst.
  ///
  /// In en, this message translates to:
  /// **'First place'**
  String get resultFirst;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @messagingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Messaging needs a backend chat contract. No messages are sent from this preview.'**
  String get messagingUnavailable;

  /// No description provided for @companyReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Company details from your account. Editing requires a company API contract.'**
  String get companyReadOnly;

  /// No description provided for @candidateGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate vs. red flags'**
  String get candidateGameTitle;

  /// No description provided for @gameInstructions.
  ///
  /// In en, this message translates to:
  /// **'Jump over red flags. Tap the game or press Space / Up.'**
  String get gameInstructions;

  /// No description provided for @gameJumpHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap or press Space / Up to jump.'**
  String get gameJumpHelp;

  /// No description provided for @gameScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameScore;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'A red flag caught you.'**
  String get gameOver;

  /// No description provided for @gameStart.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get gameStart;

  /// No description provided for @gameJump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get gameJump;

  /// No description provided for @gameRestart.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get gameRestart;

  /// No description provided for @openCandidateGame.
  ///
  /// In en, this message translates to:
  /// **'Play a mini-game'**
  String get openCandidateGame;

  /// No description provided for @closeCandidateGame.
  ///
  /// In en, this message translates to:
  /// **'Close mini-game'**
  String get closeCandidateGame;

  /// No description provided for @handshakeScene.
  ///
  /// In en, this message translates to:
  /// **'Candidate and HR recruiter meeting'**
  String get handshakeScene;

  /// No description provided for @assessments.
  ///
  /// In en, this message translates to:
  /// **'Tests and skills'**
  String get assessments;

  /// No description provided for @assessmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get assessmentHistory;

  /// No description provided for @candidateTracking.
  ///
  /// In en, this message translates to:
  /// **'Candidate tracking'**
  String get candidateTracking;

  /// No description provided for @candidateTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep a shortlist and assign skills assessments to candidates.'**
  String get candidateTrackingDescription;

  /// No description provided for @trackedCandidates.
  ///
  /// In en, this message translates to:
  /// **'Tracked candidates'**
  String get trackedCandidates;

  /// No description provided for @noTrackedCandidates.
  ///
  /// In en, this message translates to:
  /// **'No tracked candidates yet. Open a candidate profile to follow them.'**
  String get noTrackedCandidates;

  /// No description provided for @followCandidate.
  ///
  /// In en, this message translates to:
  /// **'Track candidate'**
  String get followCandidate;

  /// No description provided for @unfollowCandidate.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get unfollowCandidate;

  /// No description provided for @assignAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assign assessment'**
  String get assignAssessment;

  /// No description provided for @assessmentAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assessment assignments'**
  String get assessmentAssignments;

  /// No description provided for @noAssessmentAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assessments have been assigned to you.'**
  String get noAssessmentAssignments;

  /// No description provided for @assignmentStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignmentStatusAssigned;

  /// No description provided for @candidateLatestScore.
  ///
  /// In en, this message translates to:
  /// **'Latest score: {score}%'**
  String candidateLatestScore(int score);

  /// No description provided for @assessmentStart.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get assessmentStart;

  /// No description provided for @assessmentResume.
  ///
  /// In en, this message translates to:
  /// **'Continue test'**
  String get assessmentResume;

  /// No description provided for @assessmentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get assessmentContinue;

  /// No description provided for @assessmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get assessmentCompleted;

  /// No description provided for @assessmentInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get assessmentInProgress;

  /// No description provided for @assessmentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted · awaiting scoring'**
  String get assessmentSubmitted;

  /// No description provided for @assessmentExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get assessmentExpired;

  /// No description provided for @assessmentPendingScore.
  ///
  /// In en, this message translates to:
  /// **'Your answers were submitted. The service has not returned a score yet.'**
  String get assessmentPendingScore;

  /// No description provided for @assessmentSkillsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Skill-level feedback is not included in the available result.'**
  String get assessmentSkillsUnavailable;

  /// No description provided for @assessmentOpenReport.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get assessmentOpenReport;

  /// No description provided for @assessmentReport.
  ///
  /// In en, this message translates to:
  /// **'Test report'**
  String get assessmentReport;

  /// No description provided for @assessmentScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get assessmentScore;

  /// No description provided for @assessmentCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct answers'**
  String get assessmentCorrectAnswers;

  /// No description provided for @assessmentElapsed.
  ///
  /// In en, this message translates to:
  /// **'Time taken'**
  String get assessmentElapsed;

  /// No description provided for @assessmentStrengths.
  ///
  /// In en, this message translates to:
  /// **'Demonstrated strengths'**
  String get assessmentStrengths;

  /// No description provided for @assessmentDevelopmentAreas.
  ///
  /// In en, this message translates to:
  /// **'Skills to practice'**
  String get assessmentDevelopmentAreas;

  /// No description provided for @assessmentNoStrengths.
  ///
  /// In en, this message translates to:
  /// **'No strengths can be inferred from this attempt yet.'**
  String get assessmentNoStrengths;

  /// No description provided for @assessmentNoDevelopmentAreas.
  ///
  /// In en, this message translates to:
  /// **'No missed skills in this attempt.'**
  String get assessmentNoDevelopmentAreas;

  /// No description provided for @assessmentReflection.
  ///
  /// In en, this message translates to:
  /// **'Reflect on this result'**
  String get assessmentReflection;

  /// No description provided for @assessmentNextTests.
  ///
  /// In en, this message translates to:
  /// **'Back to available tests'**
  String get assessmentNextTests;

  /// No description provided for @assessmentFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish test'**
  String get assessmentFinish;

  /// No description provided for @assessmentOpenCatalog.
  ///
  /// In en, this message translates to:
  /// **'Open test catalog'**
  String get assessmentOpenCatalog;

  /// No description provided for @assessmentProgress.
  ///
  /// In en, this message translates to:
  /// **'Answered {answered} of {total}'**
  String assessmentProgress(int answered, int total);

  /// No description provided for @assessmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String assessmentQuestion(int current, int total);

  /// No description provided for @assessmentMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String assessmentMinutes(int minutes);

  /// No description provided for @assessmentSummary.
  ///
  /// In en, this message translates to:
  /// **'Completed tests: {count}'**
  String assessmentSummary(int count);

  /// No description provided for @assessmentCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'Completed attempts: {count}'**
  String assessmentCompletionCount(int count);

  /// No description provided for @noAssessments.
  ///
  /// In en, this message translates to:
  /// **'No tests are available right now.'**
  String get noAssessments;

  /// No description provided for @noAssessmentAttempts.
  ///
  /// In en, this message translates to:
  /// **'Start a test to see your progress here.'**
  String get noAssessmentAttempts;

  /// No description provided for @demoAssessmentNote.
  ///
  /// In en, this message translates to:
  /// **'Demonstration test · answers and score are stored locally for this app session.'**
  String get demoAssessmentNote;

  /// No description provided for @employerAssignedTest.
  ///
  /// In en, this message translates to:
  /// **'Employer assignment'**
  String get employerAssignedTest;

  /// No description provided for @achievementStarted.
  ///
  /// In en, this message translates to:
  /// **'First test started'**
  String get achievementStarted;

  /// No description provided for @achievementStartedDescription.
  ///
  /// In en, this message translates to:
  /// **'Start an available skills test.'**
  String get achievementStartedDescription;

  /// No description provided for @achievementCompleted.
  ///
  /// In en, this message translates to:
  /// **'First test completed'**
  String get achievementCompleted;

  /// No description provided for @achievementCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete every question in a test.'**
  String get achievementCompletedDescription;

  /// No description provided for @achievementInProgress.
  ///
  /// In en, this message translates to:
  /// **'Not earned yet'**
  String get achievementInProgress;

  /// No description provided for @dateReceived.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String dateReceived(String date);

  /// No description provided for @fspAchievementsNote.
  ///
  /// In en, this message translates to:
  /// **'FSP achievements come only from the existing FSP verification data.'**
  String get fspAchievementsNote;

  /// No description provided for @reflectionStrength.
  ///
  /// In en, this message translates to:
  /// **'What went well?'**
  String get reflectionStrength;

  /// No description provided for @reflectionChallenge.
  ///
  /// In en, this message translates to:
  /// **'Which tasks were difficult?'**
  String get reflectionChallenge;

  /// No description provided for @reflectionLearned.
  ///
  /// In en, this message translates to:
  /// **'What did you learn about your skills?'**
  String get reflectionLearned;

  /// No description provided for @reflectionImprove.
  ///
  /// In en, this message translates to:
  /// **'What would you like to improve?'**
  String get reflectionImprove;

  /// No description provided for @reflectionNextStep.
  ///
  /// In en, this message translates to:
  /// **'What is your next step?'**
  String get reflectionNextStep;

  /// No description provided for @reflectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save reflection'**
  String get reflectionSave;

  /// No description provided for @assessmentReflectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Reflection saved with this attempt.'**
  String get assessmentReflectionSaved;

  /// No description provided for @recruiterAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'HR AI Assistant'**
  String get recruiterAssistantTitle;

  /// No description provided for @recruiterAssistantDescription.
  ///
  /// In en, this message translates to:
  /// **'Draft interview plans, role requirements, and consistent assessment criteria.'**
  String get recruiterAssistantDescription;

  /// No description provided for @recruiterAssistantDemo.
  ///
  /// In en, this message translates to:
  /// **'Demonstration assistant. Replies are local templates, not generated by a live AI service. Do not enter candidate personal data.'**
  String get recruiterAssistantDemo;

  /// No description provided for @recruiterAssistantDemoBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get recruiterAssistantDemoBadge;

  /// No description provided for @recruiterAssistantEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask a hiring question or choose one of the example tasks below.'**
  String get recruiterAssistantEmpty;

  /// No description provided for @recruiterAssistantPrompt.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get recruiterAssistantPrompt;

  /// No description provided for @recruiterAssistantExamples.
  ///
  /// In en, this message translates to:
  /// **'Try a task'**
  String get recruiterAssistantExamples;

  /// No description provided for @recruiterAssistantInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview questions'**
  String get recruiterAssistantInterview;

  /// No description provided for @recruiterAssistantVacancy.
  ///
  /// In en, this message translates to:
  /// **'Vacancy requirements'**
  String get recruiterAssistantVacancy;

  /// No description provided for @recruiterAssistantCriteria.
  ///
  /// In en, this message translates to:
  /// **'Assessment criteria'**
  String get recruiterAssistantCriteria;

  /// No description provided for @recruiterAssistantInterviewPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prepare structured interview questions for a software engineer.'**
  String get recruiterAssistantInterviewPrompt;

  /// No description provided for @recruiterAssistantVacancyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Help structure the requirements for a software engineer vacancy.'**
  String get recruiterAssistantVacancyPrompt;

  /// No description provided for @recruiterAssistantCriteriaPrompt.
  ///
  /// In en, this message translates to:
  /// **'Suggest job-related, consistent criteria to evaluate a software engineer.'**
  String get recruiterAssistantCriteriaPrompt;

  /// No description provided for @recruiterAssistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get recruiterAssistantSend;

  /// No description provided for @recruiterAssistantClear.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get recruiterAssistantClear;

  /// No description provided for @recruiterAssistantLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing a demonstration reply…'**
  String get recruiterAssistantLoading;

  /// No description provided for @recruiterAssistantYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get recruiterAssistantYou;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
