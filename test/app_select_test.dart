import 'dart:ui' show SemanticsAction;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;
import 'package:shadcn_flutter_material/shadcn_flutter_material.dart';
import 'package:hrleaders/core/components/app_components.dart';

void main() {
  for (final platform in [TargetPlatform.linux, TargetPlatform.android]) {
    testWidgets('select options are accessible and interactive on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final semantics = tester.ensureSemantics();
      String? value;
      try {
        await tester.pumpWidget(
          MaterialShadcnApp(
            builder: (_, child) => s.DrawerOverlay(child: child!),
            home: Center(
              child: SizedBox(
                width: 320,
                child: StatefulBuilder(
                  builder: (context, setState) => AppSelect<String>(
                    label: 'Choose role',
                    value: value,
                    options: const {'hr': 'Employer', 'candidate': 'Candidate'},
                    onChanged: (selected) => setState(() => value = selected),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Choose role').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester
              .getSemantics(find.text('Employer'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester.getSize(find.byType(s.SelectItemButton<String>).first).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.text('Employer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(value, 'hr');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
