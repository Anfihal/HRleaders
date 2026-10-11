import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../features/auth/presentation/auth_bloc.dart';
import '../di/app_dependencies.dart';
import '../localization/localization.dart';
import '../routing/destinations.dart';
import '../theme/app_theme.dart';
import '../theme/preferences_bloc.dart';
import 'app_components.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final user = context.read<AppDependencies>().auth.current?.user;
    if (user == null) return const AppLoadingState();
    final destinations = destinationsFor(user);
    final path = GoRouterState.of(context).uri.path;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.compact;
        final expanded = constraints.maxWidth > AppBreakpoints.expanded;
        final primary = destinations.take(4).toList();
        final selected = primary.indexWhere((d) => path == d.path);
        final scaffoldKey = GlobalKey<m.ScaffoldState>();
        return m.Scaffold(
          key: scaffoldKey,
          drawer: compact
              ? m.Drawer(
                  child: SafeArea(
                    child: _Navigation(
                      destinations: destinations,
                      path: path,
                      onTap: (d) {
                        Navigator.of(context).pop();
                        context.go(d.path);
                      },
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: compact
              ? m.NavigationBar(
                  selectedIndex: selected < 0 ? primary.length : selected,
                  onDestinationSelected: (index) {
                    if (index == primary.length) {
                      scaffoldKey.currentState?.openDrawer();
                    } else {
                      context.go(primary[index].path);
                    }
                  },
                  destinations: [
                    for (final d in primary)
                      m.NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label(context),
                      ),
                    m.NavigationDestination(
                      icon: const Icon(m.Icons.more_horiz),
                      label: context.l.more,
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!compact)
                  Container(
                    width: expanded ? 244 : 108,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: s.Theme.of(context).colorScheme.border,
                        ),
                      ),
                    ),
                    child: _Navigation(
                      destinations: destinations,
                      path: path,
                      collapsed: !expanded,
                      onTap: (d) => context.go(d.path),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (compact)
                              AppIconButton(
                                label: context.l.menu,
                                icon: m.Icons.menu,
                                onPressed: () =>
                                    scaffoldKey.currentState?.openDrawer(),
                              ),
                            Text(
                              context.l.appName,
                              style: AppTypography.heading(context, size: 20),
                            ),
                            AppBadge(label: context.roleLabel(user.role)),
                            const PreferenceControls(),
                          ],
                        ),
                      ),
                      Container(
                        color: s.Theme.of(context).colorScheme.muted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          context.read<AppDependencies>().isDemo
                              ? context.l.demo
                              : context.l.live,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppBreakpoints.content,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(compact ? 16 : 32),
                              // Bound the nested Navigator's BlockSemantics
                              // so its route cannot hide shell navigation.
                              child: Semantics(container: true, child: child),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.destinations,
    required this.path,
    required this.onTap,
    this.collapsed = false,
  });
  final List<Destination> destinations;
  final String path;
  final ValueChanged<Destination> onTap;
  final bool collapsed;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      if (!collapsed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            context.l.appName,
            style: AppTypography.heading(context, size: 20),
          ),
        ),
      for (final d in destinations)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: m.Tooltip(
            message: d.label(context),
            excludeFromSemantics: !collapsed,
            child: m.ListTile(
              selected: path == d.path,
              leading: Icon(d.icon),
              title: collapsed ? null : Text(d.label(context)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: collapsed ? 20 : 12,
              ),
              onTap: () => onTap(d),
            ),
          ),
        ),
      const SizedBox(height: 16),
      if (collapsed)
        AppIconButton(
          label: context.l.logout,
          icon: m.Icons.logout,
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        )
      else
        AppButton(
          label: context.l.logout,
          secondary: true,
          icon: m.Icons.logout,
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        ),
    ],
  );
}

class PreferenceControls extends StatelessWidget {
  const PreferenceControls({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PreferencesBloc, AppPreferences>(
        builder: (context, state) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              label: state.locale.languageCode == 'ru'
                  ? context.l.english
                  : context.l.russian,
              secondary: true,
              onPressed: () => context.read<PreferencesBloc>().setLocale(
                Locale(state.locale.languageCode == 'ru' ? 'en' : 'ru'),
              ),
            ),
            AppButton(
              label: switch (state.theme) {
                s.ThemeMode.light => context.l.light,
                s.ThemeMode.dark => context.l.dark,
                s.ThemeMode.system => context.l.system,
              },
              secondary: true,
              icon: m.Icons.contrast,
              onPressed: () => context.read<PreferencesBloc>().setTheme(
                s.ThemeMode.values[(state.theme.index + 1) %
                    s.ThemeMode.values.length],
              ),
            ),
          ],
        ),
      );
}
