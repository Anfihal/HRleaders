import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/hiring.dart';
import 'offer_card.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ResourceBloc<List<Match>>, ResourceState<List<Match>>>(
        builder: (context, state) => ListView(
          children: [
            AppSectionHeader(
              title: context.l.matches,
              subtitle: context.l.matchTitle,
              actions: [
                AppButton(
                  label: context.l.refresh,
                  secondary: true,
                  onPressed: context.read<ResourceBloc<List<Match>>>().load,
                ),
              ],
            ),
            ResourceView(
              state: state,
              retry: context.read<ResourceBloc<List<Match>>>().load,
              emptyMessage: context.l.emptyMatches,
              builder: (matches) => Column(
                children: matches
                    .map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.96, end: 1),
                          duration: AppMotion.duration(context),
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: OfferCard(offer: match.offer),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
}
