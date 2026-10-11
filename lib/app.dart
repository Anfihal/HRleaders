import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;
import 'package:shadcn_flutter_material/shadcn_flutter_material.dart';

import 'core/di/app_dependencies.dart';
import 'core/localization/generated/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/preferences_bloc.dart';
import 'features/auth/presentation/auth_bloc.dart';

class HrleadersApp extends StatefulWidget {
  const HrleadersApp({
    super.key,
    required this.dependencies,
    required this.preferences,
    this.initialLocation,
  });
  final AppDependencies dependencies;
  final PreferencesBloc preferences;
  final String? initialLocation;
  @override
  State<HrleadersApp> createState() => _HrleadersAppState();
}

class _HrleadersAppState extends State<HrleadersApp> {
  late final AuthRouterRefresh _refresh = AuthRouterRefresh(
    widget.dependencies.authBloc,
  );
  late final GoRouter _router = createAppRouter(
    widget.dependencies,
    _refresh,
    initialLocation: widget.initialLocation,
  );
  @override
  void initState() {
    super.initState();
    widget.dependencies.authBloc.add(const RestoreSession());
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(widget.dependencies.dispose());
    unawaited(widget.preferences.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: widget.dependencies,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.dependencies.authBloc),
        BlocProvider.value(value: widget.preferences),
      ],
      child: BlocBuilder<PreferencesBloc, AppPreferences>(
        builder: (context, state) => MaterialShadcnApp.router(
          title: 'HRleaders',
          routerConfig: _router,
          builder: (context, child) => m.Theme(
            data: materialAppTheme(
              dark: s.Theme.of(context).colorScheme.brightness == Brightness.dark,
            ),
            child: s.DrawerOverlay(child: child ?? const SizedBox.shrink()),
          ),
          debugShowCheckedModeBanner: false,
          theme: appTheme(dark: false),
          darkTheme: appTheme(dark: true),
          themeMode: state.theme,
          enableThemeAnimation:
              !(MediaQuery.maybeOf(context)?.disableAnimations ??
                  WidgetsBinding
                      .instance
                      .platformDispatcher
                      .accessibilityFeatures
                      .disableAnimations),
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            m.GlobalMaterialLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
        ),
      ),
    ),
  );
}
