import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../components/app_components.dart';
import '../localization/localization.dart';
import 'preferences_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PreferencesBloc, AppPreferences>(
        builder: (context, state) => ListView(
          children: [
            AppSectionHeader(title: context.l.settings),
            AppSelect<s.ThemeMode>(
              label: context.l.theme,
              value: state.theme,
              options: {
                s.ThemeMode.light: context.l.light,
                s.ThemeMode.dark: context.l.dark,
                s.ThemeMode.system: context.l.system,
              },
              onChanged: (value) {
                if (value != null) {
                  context.read<PreferencesBloc>().setTheme(value);
                }
              },
            ),
            const SizedBox(height: 24),
            AppSelect<String>(
              label: context.l.language,
              value: state.locale.languageCode,
              options: {'ru': context.l.russian, 'en': context.l.english},
              onChanged: (value) {
                if (value != null) {
                  context.read<PreferencesBloc>().setLocale(Locale(value));
                }
              },
            ),
            const SizedBox(height: 32),
            Text(context.l.privacy),
          ],
        ),
      );
}
