import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/presentation/frame_safe_binding.dart';
import 'core/theme/preferences_bloc.dart';

Future<void> main() async {
  FrameSafeWidgetsBinding();
  const demo = bool.fromEnvironment(
    'HRLEADERS_DEMO',
    defaultValue: true,
  );
  const configured = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api/v1/',
  );
  final baseUri = kIsWeb ? Uri.base.resolve(configured) : Uri.parse(configured);
  if (!demo &&
      (!baseUri.hasAuthority || !{'http', 'https'}.contains(baseUri.scheme))) {
    throw ArgumentError('Native builds require an absolute API_BASE_URL');
  }
  runApp(
    HrleadersApp(
      dependencies: demo
          ? AppDependencies.demo()
          : AppDependencies.remote(
              baseUri,
              debugNetwork: const bool.fromEnvironment('DEBUG_NETWORK'),
            ),
      preferences: await PreferencesBloc.load(),
    ),
  );
}
