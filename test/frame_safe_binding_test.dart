import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/presentation/frame_safe_binding.dart';

class FocusTestBinding extends AutomatedTestWidgetsFlutterBinding
    with FrameSafeViewFocus {
  @override
  bool get deferViewFocus => true;
}

class LayoutObserver extends WidgetsBindingObserver {
  LayoutObserver(this.key);
  final GlobalKey key;
  final List<bool> layouts = [];
  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    layouts.add((key.currentContext!.findRenderObject()! as RenderBox).hasSize);
  }
}

void main() {
  final binding = FocusTestBinding();
  testWidgets('view focus observers receive laid-out geometry', (tester) async {
    final key = GlobalKey();
    final observer = LayoutObserver(key);
    binding.addObserver(observer);
    addTearDown(() => binding.removeObserver(observer));
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (_, _) =>
            Focus(child: SizedBox(key: key, width: 48, height: 48)),
      ),
      phase: EnginePhase.build,
    );
    binding.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: tester.view.viewId,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.forward,
      ),
    );
    expect(observer.layouts, isEmpty);
    await tester.pump();
    expect(observer.layouts, [true]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
