import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/analytics.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ResourceBloc<AnalyticsSnapshot>, ResourceState<AnalyticsSnapshot>>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(
          title: context.l.analytics,
          actions: [
            AppButton(
              label: context.l.refresh,
              secondary: true,
              onPressed: context.read<ResourceBloc<AnalyticsSnapshot>>().load,
            ),
          ],
        ),
        ResourceView(
          state: state,
          retry: context.read<ResourceBloc<AnalyticsSnapshot>>().load,
          builder: (snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(title: context.l.funnel),
              for (final item in [
                (context.l.views, snapshot.views),
                (context.l.offersSent, snapshot.sent),
                (context.l.offersOpened, snapshot.opened),
                (context.l.offersAccepted, snapshot.accepted),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: '${item.$1}: ${context.number(item.$2)}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.$1} · ${context.number(item.$2)}'),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) => Container(
                            height: 8,
                            width:
                                constraints.maxWidth *
                                (snapshot.views == 0
                                        ? 0
                                        : item.$2 / snapshot.views)
                                    .clamp(0, 1),
                            color: s.Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AppSectionHeader(title: context.l.pool),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AppStatCard(
                    label: context.l.candidates,
                    value: context.number(snapshot.candidates),
                  ),
                  AppStatCard(
                    label: context.l.verifiedCount,
                    value: context.number(snapshot.verified),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${context.l.acceptance}: ${snapshot.acceptance == null ? context.l.notAvailable : context.percent(snapshot.acceptance!)}',
              ),
              const SizedBox(height: 12),
              Text(
                '${context.l.responseTime}: ${snapshot.averageResponseHours == null ? context.l.notAvailable : context.number(snapshot.averageResponseHours!)}',
              ),
              const SizedBox(height: AppSpacing.section),
            ],
          ),
        ),
      ],
    ),
  );
}
