import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';

class EmployerHomePage extends StatelessWidget {
  const EmployerHomePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: AppSpacing.section),
      AppSectionHeader(
        title: context.l.employerTitle,
        subtitle: context.l.employerBody,
        actions: [
          AppButton(
            label: context.l.search,
            onPressed: () => context.go('/employer/candidates'),
          ),
          AppButton(
            label: context.l.vacancies,
            secondary: true,
            onPressed: () => context.go('/employer/vacancies'),
          ),
          AppButton(
            label: context.l.recruiterAssistantTitle,
            secondary: true,
            onPressed: () => context.go('/employer/assistant'),
          ),
          AppButton(
            label: context.l.candidateTracking,
            secondary: true,
            onPressed: () => context.go('/employer/tracking'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.section),
      Text(context.l.trust),
      const SizedBox(height: AppSpacing.section),
      AppSectionHeader(
        title: context.l.offers,
        actions: [
          AppButton(
            label: context.l.offers,
            secondary: true,
            onPressed: () => context.go('/employer/offers'),
          ),
          AppButton(
            label: context.l.matches,
            secondary: true,
            onPressed: () => context.go('/employer/matches'),
          ),
          AppButton(
            label: context.l.analytics,
            secondary: true,
            onPressed: () => context.go('/employer/analytics'),
          ),
        ],
      ),
    ],
  );
}
