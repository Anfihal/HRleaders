import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

abstract final class AppColors {
  static const brand = Color(0xFF4028FF);
  static const danger = Color(0xFFEC1D35);
  static const white = Color(0xFFFFFFFF);

  static const lightBackground = Color(0xFFF3F1F1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightForeground = Color(0xFF171719);
  static const lightMuted = Color(0xFF777579);
  static const lightMutedSurface = Color(0xFFEDEDED);
  static const lightBorder = Color(0xFFE8E6E6);

  static const darkBackground = Color(0xFF1B1C20);
  static const darkSurface = Color(0xFF1B1C20);
  static const darkForeground = Color(0xFFF5F4F4);
  static const darkMuted = Color(0xFFAAA9AD);
  static const darkMutedSurface = Color(0xFF303136);
  static const darkBorder = Color(0xFF303136);

  static const aboutPanel = Color(0xFFC9C9CB);
}

abstract final class AppSpacing {
  static const extraSmall = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const extraLarge = 32.0;
  static const section = 48.0;
}

abstract final class AppRadii {
  static const small = 8.0;
  static const card = 12.0;
  static const large = 16.0;
  static const pill = 62.0;
}

abstract final class AppButtonMetrics {
  static const minHeight = 48.0;
  static const iconSize = 48.0;
  static const iconVisualSize = 20.0;
  static const iconGap = 8.0;
  static const horizontalPadding = 16.0;
  static const verticalPadding = 12.0;
}

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const expanded = 1024.0;
  static const content = 1240.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 450);
  static const spring = Curves.easeOutCubic;

  static Duration duration(BuildContext context) =>
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
      ? Duration.zero
      : normal;
}

abstract final class AppTypography {
  static const family = 'JetBrains Mono';

  static TextStyle heading(BuildContext context, {double size = 28}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: s.Theme.of(context).colorScheme.foreground,
      );
}

s.ThemeData appTheme({required bool dark}) {
  final background = dark
      ? AppColors.darkBackground
      : AppColors.lightBackground;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final foreground = dark
      ? AppColors.darkForeground
      : AppColors.lightForeground;
  final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
  final mutedSurface = dark
      ? AppColors.darkMutedSurface
      : AppColors.lightMutedSurface;
  final border = dark ? AppColors.darkBorder : AppColors.lightBorder;

  final colors = (dark ? s.ColorSchemes.darkZinc : s.ColorSchemes.lightZinc)
      .copyWith(
        brightness: () => dark ? Brightness.dark : Brightness.light,
        background: () => background,
        foreground: () => foreground,
        card: () => surface,
        cardForeground: () => foreground,
        popover: () => surface,
        popoverForeground: () => foreground,
        primary: () => AppColors.brand,
        primaryForeground: () => AppColors.white,
        secondary: () => mutedSurface,
        secondaryForeground: () => foreground,
        muted: () => mutedSurface,
        mutedForeground: () => muted,
        accent: () => mutedSurface,
        accentForeground: () => foreground,
        destructive: () => AppColors.danger,
        destructiveForeground: () => AppColors.white,
        border: () => border,
        input: () => border,
        ring: () => AppColors.brand,
        chart1: () => AppColors.brand,
        chart2: () => AppColors.danger,
      );

  return s.ThemeData(
    colorScheme: colors,
    radius: 0.5,
    typography: const s.Typography.geist().copyWith(
      sans: () => const TextStyle(fontFamily: AppTypography.family),
      mono: () => const TextStyle(fontFamily: AppTypography.family),
    ),
  );
}

m.ThemeData materialAppTheme({required bool dark}) {
  final background = dark
      ? AppColors.darkBackground
      : AppColors.lightBackground;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final foreground = dark
      ? AppColors.darkForeground
      : AppColors.lightForeground;
  final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
  final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
  final brightness = dark ? Brightness.dark : Brightness.light;

  final colorScheme =
      m.ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: brightness,
        surface: surface,
      ).copyWith(
        primary: AppColors.brand,
        onPrimary: AppColors.white,
        secondary: AppColors.brand,
        onSecondary: AppColors.white,
        error: AppColors.danger,
        onError: AppColors.white,
        tertiary: AppColors.danger,
        onTertiary: AppColors.white,
        surface: surface,
        surfaceTint: surface,
        onSurface: foreground,
        onSurfaceVariant: muted,
        outline: border,
        outlineVariant: border,
        inverseSurface: foreground,
        onInverseSurface: background,
        inversePrimary: AppColors.brand,
      );

  final baseTheme = m.ThemeData.from(colorScheme: colorScheme);
  final textTheme = baseTheme.textTheme.apply(
    bodyColor: foreground,
    displayColor: foreground,
    fontFamily: AppTypography.family,
  );

  return baseTheme.copyWith(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: border,
    textTheme: textTheme.copyWith(
      bodySmall: textTheme.bodySmall?.copyWith(color: muted),
      labelSmall: textTheme.labelSmall?.copyWith(color: muted),
    ),
    filledButtonTheme: m.FilledButtonThemeData(
      style: m.FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, AppButtonMetrics.minHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppButtonMetrics.horizontalPadding,
          vertical: AppButtonMetrics.verticalPadding,
        ),
        shape: const StadiumBorder(),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    ),
    elevatedButtonTheme: m.ElevatedButtonThemeData(
      style: m.ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, AppButtonMetrics.minHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppButtonMetrics.horizontalPadding,
          vertical: AppButtonMetrics.verticalPadding,
        ),
        shape: const StadiumBorder(),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: m.OutlinedButtonThemeData(
      style: m.OutlinedButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(0, AppButtonMetrics.minHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppButtonMetrics.horizontalPadding,
          vertical: AppButtonMetrics.verticalPadding,
        ),
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    ),
    textButtonTheme: m.TextButtonThemeData(
      style: m.TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size(0, AppButtonMetrics.minHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppButtonMetrics.horizontalPadding,
          vertical: AppButtonMetrics.verticalPadding,
        ),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    ),
    iconButtonTheme: m.IconButtonThemeData(
      style: m.ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(AppButtonMetrics.iconSize, AppButtonMetrics.iconSize),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        alignment: Alignment.center,
      ),
    ),
  );
}
