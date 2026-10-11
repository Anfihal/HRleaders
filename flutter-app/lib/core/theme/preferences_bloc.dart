import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show ThemeMode;

final class AppPreferences {
  const AppPreferences({
    this.theme = ThemeMode.system,
    this.locale = const Locale('ru'),
  });
  final ThemeMode theme;
  final Locale locale;
}

final class PreferencesBloc extends Cubit<AppPreferences> {
  PreferencesBloc({
    this._storage,
    AppPreferences initial = const AppPreferences(),
  }) : super(initial);
  final SharedPreferences? _storage;
  static Future<PreferencesBloc> load() async {
    final storage = await SharedPreferences.getInstance();
    final theme =
        ThemeMode.values
            .where((v) => v.name == storage.getString('theme'))
            .firstOrNull ??
        ThemeMode.system;
    final locale = storage.getString('locale');
    return PreferencesBloc(
      storage: storage,
      initial: AppPreferences(
        theme: theme,
        locale: Locale(locale == 'en' ? 'en' : 'ru'),
      ),
    );
  }

  Future<void> setTheme(ThemeMode theme) async {
    emit(AppPreferences(theme: theme, locale: state.locale));
    await _storage?.setString('theme', theme.name);
  }

  Future<void> setLocale(Locale locale) async {
    emit(AppPreferences(theme: state.theme, locale: locale));
    await _storage?.setString('locale', locale.languageCode);
  }
}
