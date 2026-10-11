import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/hiring.dart';
import 'hiring_blocs.dart';

class VacancyForm extends StatefulWidget {
  const VacancyForm({super.key});
  @override
  State<VacancyForm> createState() => _VacancyFormState();
}

class _VacancyFormState extends State<VacancyForm> {
  final _title = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _description = TextEditingController();
  final _skills = TextEditingController();
  AppFailure? _failure;
  @override
  void dispose() {
    for (final c in [_title, _from, _to, _description, _skills]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    try {
      final from = int.tryParse(_from.text);
      final to = int.tryParse(_to.text);
      if (from == null || to == null) {
        throw const AppFailure(FailureKind.validation, 'invalid_salary');
      }
      final bloc = context.read<VacanciesBloc>();
      await bloc.publish(
        VacancyDraft(
          title: _title.text,
          salary: SalaryRange(from, to),
          description: _description.text,
          skills: _skills.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        ),
      );
      if (mounted && bloc.state.failure == null) Navigator.of(context).pop();
    } on AppFailure catch (error) {
      setState(() => _failure = error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<VacanciesBloc, ResourceState<List<Vacancy>>>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: context.l.vacancyTitle, controller: _title),
            const SizedBox(height: 16),
            AppTextField(
              label: context.l.salaryFrom,
              controller: _from,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: context.l.salaryTo,
              controller: _to,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(label: context.l.skills, controller: _skills),
            const SizedBox(height: 16),
            AppTextField(
              label: context.l.description,
              controller: _description,
              lines: 4,
            ),
            const SizedBox(height: 16),
            if (_failure != null || state.failure != null)
              Text(context.failureLabel(_failure ?? state.failure!)),
            AppButton(
              label: context.l.createVacancy,
              onPressed: _publish,
              busy: state.busy,
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
