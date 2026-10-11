import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/hiring.dart';
import 'hiring_blocs.dart';
import 'send_offer_bloc.dart';

class SendOfferForm extends StatefulWidget {
  const SendOfferForm({super.key, required this.candidateId});
  final EntityId candidateId;
  @override
  State<SendOfferForm> createState() => _SendOfferFormState();
}

class _SendOfferFormState extends State<SendOfferForm> {
  final _salary = TextEditingController();
  final _message = TextEditingController();
  String? _vacancyId;
  AppFailure? _failure;
  @override
  void dispose() {
    _salary.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send(List<Vacancy> vacancies) {
    try {
      final vacancy = vacancies
          .where((v) => v.id.value == _vacancyId)
          .firstOrNull;
      final amount = int.tryParse(_salary.text);
      if (vacancy == null || amount == null) {
        throw const AppFailure(FailureKind.validation, 'invalid_offer');
      }
      context.read<SendOfferBloc>().send(
        OfferDraft(
          vacancy: vacancy,
          candidateId: widget.candidateId,
          salary: Salary(amount),
          message: _message.text,
        ),
      );
    } on AppFailure catch (error) {
      setState(() => _failure = error);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SendOfferBloc, ResourceState<Offer>>(
    listener: (context, state) {
      if (state.saved) Navigator.of(context).pop(true);
    },
    builder: (context, sendState) =>
        BlocBuilder<VacanciesBloc, ResourceState<List<Vacancy>>>(
          builder: (context, state) => ResourceView(
            state: state,
            retry: context.read<VacanciesBloc>().load,
            builder: (vacancies) {
              final open = vacancies.where((v) => v.isOpen).toList();
              if (open.isEmpty) {
                return AppEmptyState(message: context.l.createVacancy);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSelect<String>(
                    label: context.l.vacancies,
                    value: _vacancyId,
                    options: {for (final v in open) v.id.value: v.title},
                    onChanged: (id) => setState(() {
                      _vacancyId = id;
                      _salary.text = open
                          .firstWhere((v) => v.id.value == id)
                          .salary
                          .from
                          .amount
                          .toString();
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_vacancyId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${context.money(open.firstWhere((v) => v.id.value == _vacancyId).salary.from.amount)} — ${context.money(open.firstWhere((v) => v.id.value == _vacancyId).salary.to.amount)}',
                      ),
                    ),
                  AppTextField(
                    label: context.l.salary,
                    controller: _salary,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: context.l.offerMessage,
                    controller: _message,
                    lines: 4,
                  ),
                  const SizedBox(height: 16),
                  if (_failure != null || sendState.failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        context.failureLabel(_failure ?? sendState.failure!),
                      ),
                    ),
                  AppButton(
                    label: context.l.sendOffer,
                    onPressed: () => _send(open),
                    busy: sendState.busy,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: context.l.cancel,
                    secondary: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        ),
  );
}
