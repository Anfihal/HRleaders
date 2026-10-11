import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../../core/components/app_components.dart';
import '../../../core/components/app_shell.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => m.Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < AppBreakpoints.compact;
          final colors = s.Theme.of(context).colorScheme;
          return ListView(
            controller: _scroll,
            padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 48),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.content,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 20,
                          runSpacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              context.l.appName,
                              style: AppTypography.heading(context, size: 24),
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                const PreferenceControls(),
                                AppButton(
                                  label: context.l.login,
                                  onPressed: () => context.go('/login'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (context.read<AppDependencies>().isDemo)
                        AppBadge(label: context.l.demo),
                      const SizedBox(height: 48),
                      Text(
                        context.l.tagline.toUpperCase(),
                        style: TextStyle(
                          color: colors.mutedForeground,
                          letterSpacing: 1.4,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l.heroTitle,
                        style: AppTypography.heading(
                          context,
                          size: narrow ? 36 : 72,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          context.l.heroBody,
                          style: const TextStyle(fontSize: 18, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          AppButton(
                            label: context.l.candidateCta,
                            icon: m.Icons.person_outline,
                            onPressed: () =>
                                context.go('/register?role=candidate'),
                          ),
                          AppButton(
                            label: context.l.employerCta,
                            icon: m.Icons.work_outline,
                            secondary: true,
                            onPressed: () => context.go('/register?role=hr'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Semantics(
                        label:
                            '${context.l.candidate} · ${context.l.handshakeScene} · ${context.l.employer}',
                        image: true,
                        child: SizedBox(
                          height: narrow ? 300 : 420,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 48),
                                child: Image.asset(
                                  'assets/images/handshake.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: _CharacterLabel(
                                          label: context.l.candidate,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Center(
                                        child: _CharacterLabel(
                                          label: context.l.employer,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, box) => Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            for (final story in [
                              (context.l.fight, context.l.fightBody),
                              (context.l.tap, context.l.tapBody),
                              (context.l.networkStage, context.l.networkBody),
                              (
                                context.l.connectionStage,
                                context.l.connectionBody,
                              ),
                              (context.l.hug, context.l.hugBody),
                              (context.l.trustStage, context.l.trustBody),
                              (context.l.matchStage, context.l.matchBody),
                            ])
                              SizedBox(
                                width: box.maxWidth < 800
                                    ? box.maxWidth
                                    : (box.maxWidth - 40) / 3,
                                child: AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        story.$1,
                                        style: AppTypography.heading(
                                          context,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        story.$2,
                                        style: const TextStyle(height: 1.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 72),
                      Text(
                        context.l.aboutTitle,
                        style: AppTypography.heading(
                          context,
                          size: narrow ? 32 : 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l.aboutBody,
                        style: const TextStyle(fontSize: 20, height: 1.6),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        context.l.trust,
                        style: AppTypography.heading(context, size: 20),
                      ),
                      const SizedBox(height: 72),
                      AppSectionHeader(title: context.l.team),
                      LayoutBuilder(
                        builder: (context, box) => Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            for (final member in [
                              (
                                context.l.dmitry,
                                context.l.cto,
                                context.l.teamEngineering,
                              ),
                              (
                                context.l.anfisa,
                                context.l.fspLead,
                                context.l.teamVerification,
                              ),
                              (
                                context.l.artem,
                                context.l.productLead,
                                context.l.teamProduct,
                              ),
                            ])
                              SizedBox(
                                width: box.maxWidth < 800
                                    ? box.maxWidth
                                    : (box.maxWidth - 40) / 3,
                                child: AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppAvatar(name: member.$1),
                                      const SizedBox(height: 20),
                                      Text(
                                        member.$1,
                                        style: AppTypography.heading(
                                          context,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(member.$2),
                                      const SizedBox(height: 16),
                                      Text(member.$3),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 72),
                      const AppSecurityBadge(),
                      const SizedBox(height: 20),
                      Text(
                        context.l.securityTitle,
                        style: AppTypography.heading(context),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l.securityBody,
                        style: const TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 48),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          AppButton(
                            label: context.l.candidateCta,
                            onPressed: () =>
                                context.go('/register?role=candidate'),
                          ),
                          AppButton(
                            label: context.l.employerCta,
                            secondary: true,
                            onPressed: () => context.go('/register?role=hr'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CharacterLabel extends StatelessWidget {
  const _CharacterLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
