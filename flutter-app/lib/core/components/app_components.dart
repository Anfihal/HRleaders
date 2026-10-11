import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../error/app_failure.dart';
import '../localization/localization.dart';
import '../presentation/resource_state.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.secondary = false,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppButtonMetrics.minHeight,
          minWidth: AppButtonMetrics.minHeight,
        ),
        child: s.ButtonStyleOverride(
          padding: (_, _, _) => const EdgeInsets.symmetric(
            horizontal: AppButtonMetrics.horizontalPadding,
            vertical: AppButtonMetrics.verticalPadding,
          ),
          child: secondary
              ? s.OutlineButton(
                  onPressed: busy ? null : onPressed,
                  alignment: Alignment.center,
                  shape: s.ButtonShape.rectangle,
                  leading: _leading(),
                  child: _label(),
                )
              : s.PrimaryButton(
                  onPressed: busy ? null : onPressed,
                  alignment: Alignment.center,
                  shape: s.ButtonShape.rectangle,
                  leading: _leading(),
                  child: _label(),
                ),
        ),
      ),
    );
  }

  Widget? _leading() {
    if (busy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: s.CircularProgressIndicator(),
      );
    }
    return icon == null ? null : Icon(icon, size: 18);
  }

  Widget _label() => Text(label, textAlign: TextAlign.center, softWrap: true);
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => m.IconButton(
    tooltip: label,
    icon: Icon(icon),
    iconSize: AppButtonMetrics.iconVisualSize,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(
      width: AppButtonMetrics.iconSize,
      height: AppButtonMetrics.iconSize,
    ),
    padding: EdgeInsets.zero,
    alignment: Alignment.center,
  );
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AppIconButton(
    label: context.l.back,
    icon: m.Icons.arrow_back,
    onPressed: onPressed,
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.lines = 1,
    this.keyboardType,
    this.error,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final int lines;
  final TextInputType? keyboardType;
  final String? error;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: AppSpacing.small),
      Semantics(
        label: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: s.TextField(
            controller: controller,
            obscureText: obscure,
            maxLines: lines,
            keyboardType: keyboardType,
            enabled: enabled,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
          ),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            error!,
            style: TextStyle(
              color: s.Theme.of(context).colorScheme.destructive,
            ),
          ),
        ),
    ],
  );
}

class AppSearchField extends AppTextField {
  const AppSearchField({
    super.key,
    required super.label,
    required super.controller,
    super.onSubmitted,
  });
}

class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
  });
  final String label;
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: AppSpacing.small),
      Semantics(
        label: label,
        child: SizedBox(
          width: double.infinity,
          child: s.Select<T>(
            value: value,
            onChanged: onChanged,
            placeholder: ExcludeSemantics(child: Text(label)),
            constraints: const BoxConstraints(minHeight: 48),
            itemBuilder: (context, item) => Text(
              options[item] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            popup: (context) => s.SelectPopup<T>(
              items: s.SelectItemList(
                children: [
                  for (final entry in options.entries)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: s.SelectItemButton<T>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      s.Card(padding: const EdgeInsets.all(AppSpacing.large), child: child);
}

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => s.SecondaryBadge(
    child: Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [if (icon != null) Icon(icon, size: 14), Text(label)],
    ),
  );
}

class AppChip extends AppBadge {
  const AppChip({super.key, required super.label});
}

class AppVerifiedBadge extends StatelessWidget {
  const AppVerifiedBadge({super.key, required this.verified});
  final bool verified;
  @override
  Widget build(BuildContext context) => AppBadge(
    label: verified ? context.l.verified : context.l.unverified,
    icon: verified ? m.Icons.verified_outlined : m.Icons.hourglass_empty,
  );
}

class AppSecurityBadge extends StatelessWidget {
  const AppSecurityBadge({super.key});
  @override
  Widget build(BuildContext context) =>
      AppBadge(label: context.l.security, icon: m.Icons.shield_outlined);
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: s.Theme.of(context).colorScheme.muted,
    ),
    child: Text(
      name
          .split(' ')
          .where((p) => p.isNotEmpty)
          .take(2)
          .map((p) => p[0])
          .join(),
      style: AppTypography.heading(context, size: 16),
    ),
  );
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.large),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(title, style: AppTypography.heading(context)),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.small),
            child: Semantics(container: true, child: Text(subtitle!)),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.medium),
            child: Wrap(spacing: 8, runSpacing: 8, children: actions),
          ),
      ],
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
    child: Center(
      child: Column(
        children: [
          const Icon(m.Icons.inbox_outlined, size: 40),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l.loading,
    liveRegion: true,
    child: const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: s.CircularProgressIndicator()),
    ),
  );
}

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: 96, color: s.Theme.of(context).colorScheme.muted);
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.failure, required this.retry});
  final AppFailure failure;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(context.failureLabel(failure), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppButton(label: context.l.retry, onPressed: retry, secondary: true),
        ],
      ),
    ),
  );
}

class AppStatCard extends StatelessWidget {
  const AppStatCard({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 12),
        Text(value, style: AppTypography.heading(context)),
      ],
    ),
  );
}

class ResourceView<T> extends StatelessWidget {
  const ResourceView({
    super.key,
    required this.state,
    required this.retry,
    required this.builder,
    this.emptyMessage,
  });
  final ResourceState<T> state;
  final VoidCallback retry;
  final Widget Function(T) builder;
  final String? emptyMessage;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.busy) const AppLoadingState(),
      if (state.failure != null)
        AppErrorState(failure: state.failure!, retry: retry),
      if (state.saved)
        Semantics(liveRegion: true, child: Text(context.l.saved)),
      if (state.phase == ResourcePhase.empty)
        AppEmptyState(message: emptyMessage ?? context.l.empty)
      else if (state.value != null)
        builder(state.value as T),
    ],
  );
}

Future<T?> appDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) => m.showDialog<T>(
  context: context,
  builder: (context) => m.Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: title),
            child,
          ],
        ),
      ),
    ),
  ),
);

Future<T?> appBottomSheet<T>(BuildContext context, Widget child) =>
    m.showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    );
