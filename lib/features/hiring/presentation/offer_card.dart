import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/hiring.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.actions = const []});
  final Offer offer;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          offer.vacancy.title,
          style: AppTypography.heading(context, size: 20),
        ),
        const SizedBox(height: 8),
        Text('${offer.companyName} · ${offer.candidateName}'),
        const SizedBox(height: 16),
        AppBadge(
          label: context.statusLabel(offer.status),
          icon: offer.status == OfferStatus.accepted
              ? m.Icons.hub_outlined
              : m.Icons.mail_outline,
        ),
        const SizedBox(height: 16),
        Text(
          context.money(offer.salary.amount),
          style: AppTypography.heading(context, size: 24),
        ),
        const SizedBox(height: 12),
        Text(offer.message),
        const SizedBox(height: 12),
        Text(context.date(offer.createdAt)),
        if (offer.declineReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('${context.l.declineReason}: ${offer.declineReason}'),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: actions),
          ),
      ],
    ),
  );
}
