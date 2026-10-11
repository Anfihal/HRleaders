import 'dart:ui' show ViewFocusEvent;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Flutter web can deliver its initial view-focus event before render boxes
/// have been laid out. Reading-order traversal requires their geometry.
/// Dispatch web focus notifications after layout, preserving event order.
mixin FrameSafeViewFocus on WidgetsBinding {
  @protected
  bool get deferViewFocus => kIsWeb;

  @override
  void handleViewFocusChanged(ViewFocusEvent event) {
    if (!deferViewFocus) {
      super.handleViewFocusChanged(event);
      return;
    }
    addPostFrameCallback((_) => super.handleViewFocusChanged(event));
    ensureVisualUpdate();
  }
}

class FrameSafeWidgetsBinding extends WidgetsFlutterBinding
    with FrameSafeViewFocus {}
