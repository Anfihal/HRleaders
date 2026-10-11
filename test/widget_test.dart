import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;
import 'package:hrleaders/app.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/theme/preferences_bloc.dart';
import 'package:hrleaders/features/hiring/presentation/offers_page.dart';
import 'package:hrleaders/features/hiring/presentation/matches_page.dart';
import 'package:hrleaders/features/candidates/presentation/candidate_search_page.dart';

void main() {
  testWidgets(
    'shell navigation and preferences remain accessible around nested routes',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final deps = AppDependencies.demo();
      await deps.auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
      await tester.pumpWidget(
        HrleadersApp(
          dependencies: deps,
          preferences: PreferencesBloc(),
          initialLocation: '/employer',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Кандидаты'), findsWidgets);
      expect(find.bySemanticsLabel('English'), findsWidgets);
      expect(find.bySemanticsLabel('Выйти'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final locale in ['ru', 'en']) {
      testWidgets('search adapts at $width px in $locale with large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final deps = AppDependencies.demo();
        await deps.auth.login(Email('hr@demo.hrleaders.example'), 'Demo12345');
        await tester.pumpWidget(
          HrleadersApp(
            dependencies: deps,
            preferences: PreferencesBloc(
              initial: AppPreferences(
                locale: Locale(locale),
                theme: locale == 'ru' ? s.ThemeMode.light : s.ThemeMode.dark,
              ),
            ),
            initialLocation: '/employer/candidates',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CandidateSearchPage), findsOneWidget);
        expect(find.text('Daria Orlova'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('accepting an offer updates the distinct Matches screen', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deps = AppDependencies.demo();
    await deps.auth.login(
      Email('candidate@demo.hrleaders.example'),
      'Demo12345',
    );
    await tester.pumpWidget(
      HrleadersApp(
        dependencies: deps,
        preferences: PreferencesBloc(
          initial: const AppPreferences(
            locale: Locale('en'),
            theme: s.ThemeMode.dark,
          ),
        ),
        initialLocation: '/candidate/offers',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept offer'));
    await tester.pumpAndSettle();
    expect(find.text('Accepted · match'), findsOneWidget);
    GoRouter.of(tester.element(find.byType(OffersPage)))
        .go('/candidate/matches');
    await tester.pumpAndSettle();
    expect(find.byType(MatchesPage), findsOneWidget);
    expect(find.text('A connection made.'), findsOneWidget);
    expect(find.bySemanticsLabel('A connection made.'), findsOneWidget);
    expect(find.bySemanticsLabel('Refresh'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
  testWidgets('landing exposes both registration paths', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      HrleadersApp(
        dependencies: AppDependencies.demo(),
        preferences: PreferencesBloc(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Раньше — битва.\nТеперь — объятия.'), findsOneWidget);
    expect(find.text('Я — Кандидат'), findsWidgets);
    expect(find.text('Я — Работодатель'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
