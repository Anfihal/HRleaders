import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/hiring.dart';
import 'hiring_blocs.dart';
import 'offer_card.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key, this.focusId});
  final EntityId? focusId;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OffersBloc, ResourceState<List<Offer>>>(
        builder: (context, state) {
          final bloc = context.read<OffersBloc>();
          return ListView(
            children: [
              AppSectionHeader(
                title: context.l.offers,
                subtitle: bloc.incoming ? context.l.incomingTitle : null,
                actions: [
                  AppButton(
                    label: context.l.refresh,
                    secondary: true,
                    onPressed: state.busy ? null : bloc.load,
                  ),
                ],
              ),
              ResourceView(
                state: state,
                retry: bloc.load,
                emptyMessage: context.l.emptyOffers,
                builder: (offers) => Column(
                  children: [
                    if (focusId != null && !offers.any((o) => o.id == focusId))
                      AppEmptyState(message: context.l.notFound),
                    for (final offer in offers.where(
                      (o) => focusId == null || o.id == focusId,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OfferCard(
                          offer: offer,
                          actions: offer.awaitsResponse
                              ? [
                                  if (bloc.incoming) ...[
                                    if (offer.status == OfferStatus.sent)
                                      AppButton(
                                        label: context.l.viewOffer,
                                        secondary: true,
                                        onPressed: state.busy
                                            ? null
                                            : () => bloc.action(
                                                offer.id,
                                                OfferStatus.viewed,
                                              ),
                                      ),
                                    AppButton(
                                      label: context.l.accept,
                                      onPressed: state.busy
                                          ? null
                                          : () => bloc.action(
                                              offer.id,
                                              OfferStatus.accepted,
                                            ),
                                    ),
                                    AppButton(
                                      label: context.l.decline,
                                      secondary: true,
                                      onPressed: state.busy
                                          ? null
                                          : () => appDialog(
                                              context,
                                              title: context.l.decline,
                                              child: BlocProvider.value(
                                                value: bloc,
                                                child: DeclineForm(
                                                  id: offer.id,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ] else
                                    AppButton(
                                      label: context.l.withdraw,
                                      secondary: true,
                                      onPressed: state.busy
                                          ? null
                                          : () => bloc.action(
                                              offer.id,
                                              OfferStatus.withdrawn,
                                            ),
                                    ),
                                ]
                              : [],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class DeclineForm extends StatefulWidget {
  const DeclineForm({super.key, required this.id});
  final EntityId id;
  @override
  State<DeclineForm> createState() => _DeclineFormState();
}

class _DeclineFormState extends State<DeclineForm> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OffersBloc, ResourceState<List<Offer>>>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: context.l.declineReason,
              controller: _reason,
              lines: 3,
            ),
            const SizedBox(height: 16),
            if (state.failure != null)
              Text(context.failureLabel(state.failure!)),
            AppButton(
              label: context.l.decline,
              busy: state.busy,
              onPressed: () async {
                final bloc = context.read<OffersBloc>();
                await bloc.action(
                  widget.id,
                  OfferStatus.declined,
                  reason: _reason.text,
                );
                if (context.mounted && bloc.state.failure == null) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: context.l.cancel,
              secondary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
}
