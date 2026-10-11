import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;
import 'package:hrleaders/app.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/theme/preferences_bloc.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('recruiter tracks a candidate and assigns an assessment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dependencies = AppDependencies.demo();
    await dependencies.auth.login(
      Email('hr@demo.hrleaders.example'),
      'Demo12345',
    );
    await tester.pumpWidget(
      HrleadersApp(
        dependencies: dependencies,
        preferences: PreferencesBloc(
          initial: AppPreferences(
            locale: const Locale('en'),
            theme: s.ThemeMode.light,
          ),
        ),
        initialLocation: '/employer/tracking',
      ),
    );
    await _pumpApp(tester);
    await tester.tap(find.text('Search candidates'));
    await _pumpApp(tester);
    await tester.tap(find.text('View profile').first);
    await _pumpApp(tester);

    await tester.tap(find.text('Track candidate'));
    await _pumpApp(tester);
    await tester.tap(find.text('Assign assessment'));
    await _pumpApp(tester);
    await tester.tap(find.textContaining('Algorithmic reasoning').last);
    await _pumpApp(tester);

    expect(
      (await dependencies.recruiterCjm.followedCandidates()).single.name,
      'Daria Orlova',
    );
    expect(await dependencies.recruiterCjm.assignments(), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
