import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/presentation/resource_state.dart';
import '../application/hiring_use_cases.dart';
import '../domain/hiring.dart';

final class SendOfferBloc extends Cubit<ResourceState<Offer>> {
  SendOfferBloc(this.sendOffer)
    : super(const ResourceState(ResourcePhase.initial));
  final SendOffer sendOffer;
  Future<void> send(OfferDraft draft) async {
    if (state.busy) return;
    emit(const ResourceState(ResourcePhase.saving));
    try {
      final offer = await sendOffer(draft);
      if (!isClosed) {
        emit(ResourceState(ResourcePhase.loaded, value: offer, saved: true));
      }
    } on AppFailure catch (error) {
      if (!isClosed) emit(ResourceState(ResourcePhase.failure, failure: error));
    }
  }
}
