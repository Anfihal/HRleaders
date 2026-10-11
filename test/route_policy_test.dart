import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/routing/route_policy.dart';
import 'package:hrleaders/core/routing/destinations.dart';

void main() {
  test(
    'protected return links survive sign-in without open redirects',
    () async {
      final deps = AppDependencies.demo();
      final target = Uri.parse(
        '/employer/candidates/00000000-0000-4000-8000-000000000200',
      );
      final login = Uri.parse(routeRedirect(target, null, restoring: false)!);
      expect(login.path, '/login');
      expect(login.queryParameters['from'], target.toString());
      final hr = (await deps.auth.login(
        Email('hr@demo.hrleaders.example'),
        'Demo12345',
      )).user;
      expect(routeRedirect(login, hr, restoring: false), target.toString());
      expect(
        routeRedirect(
          Uri.parse('/login?from=https://example.com'),
          hr,
          restoring: false,
        ),
        '/employer',
      );
      expect(
        routeRedirect(
          Uri.parse('/login?from=//example.com'),
          hr,
          restoring: false,
        ),
        '/employer',
      );
      final candidate = (await deps.auth.login(
        Email('candidate@demo.hrleaders.example'),
        'Demo12345',
      )).user;
      expect(routeRedirect(target, candidate, restoring: false), '/forbidden');
      expect(
        destinationsFor(candidate).any((d) => d == Destination.candidates),
        isFalse,
      );
      expect(
        normalizeAppLink(Uri.parse('hrleaders://offer/123')),
        '/offer/123',
      );
      await deps.dispose();
    },
  );
}
