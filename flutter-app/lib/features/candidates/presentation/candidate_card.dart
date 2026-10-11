import 'package:flutter/widgets.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/candidates.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate, required this.open});
  final Candidate candidate;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(name: candidate.name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: AppTypography.heading(context, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(candidate.headline),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppVerifiedBadge(verified: candidate.verified),
            if (candidate.grade != null)
              AppChip(label: context.gradeLabel(candidate.grade!)),
            if (candidate.workFormat != null)
              AppChip(label: context.formatLabel(candidate.workFormat!)),
            if (candidate.city != null) AppChip(label: candidate.city!),
            ...candidate.skills.map((skill) => AppChip(label: skill)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          candidate.salary == null
              ? context.l.noSalary
              : context.money(candidate.salary!.amount),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: context.l.viewProfile,
          secondary: true,
          onPressed: open,
        ),
      ],
    ),
  );
}
