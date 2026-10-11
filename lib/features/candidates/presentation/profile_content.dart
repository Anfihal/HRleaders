import 'package:flutter/widgets.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/candidates.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.profile});
  final Candidate profile;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: profile.name),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTypography.heading(context)),
                const SizedBox(height: 8),
                Text(profile.headline),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppVerifiedBadge(verified: profile.verified),
          if (profile.grade != null)
            AppChip(label: context.gradeLabel(profile.grade!)),
          if (profile.city != null) AppChip(label: profile.city!),
          if (profile.workFormat != null)
            AppChip(label: context.formatLabel(profile.workFormat!)),
          ...profile.skills.map((s) => AppChip(label: s)),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        profile.salary == null
            ? context.l.noSalary
            : context.money(profile.salary!.amount),
      ),
      if (profile.about != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(profile.about!),
        ),
      if (profile.syncedAt != null)
        Text('${context.l.lastSync}: ${context.date(profile.syncedAt!)}'),
      const SizedBox(height: 32),
      AppSectionHeader(title: context.l.categories),
      for (final category in profile.categories)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.referenceLabel(category.discipline)} · ${context.referenceLabel(category.level)}',
                ),
                Text('${context.l.points}: ${context.number(category.score)}'),
                if (category.pointsToNextLevel != null)
                  Text(
                    '${context.l.nextLevel}: ${context.number(category.pointsToNextLevel!)}',
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 24),
      AppSectionHeader(title: context.l.achievements),
      if (profile.achievements.isEmpty)
        AppEmptyState(message: context.l.unverified),
      for (final achievement in profile.achievements)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.competition),
                Text(
                  '${context.date(achievement.date)} · ${context.referenceLabel(achievement.discipline)} · ${context.referenceLabel(achievement.result)}',
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
