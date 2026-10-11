import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/hiring.dart';
import 'hiring_blocs.dart';
import 'vacancy_form.dart';

class VacanciesPage extends StatelessWidget {
  const VacanciesPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<VacanciesBloc, ResourceState<List<Vacancy>>>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(
          title: context.l.vacancies,
          actions: [
            AppButton(
              label: context.l.createVacancy,
              onPressed: () => appDialog(
                context,
                title: context.l.createVacancy,
                child: BlocProvider.value(
                  value: context.read<VacanciesBloc>(),
                  child: const VacancyForm(),
                ),
              ),
            ),
            AppButton(
              label: context.l.refresh,
              secondary: true,
              onPressed: state.busy ? null : context.read<VacanciesBloc>().load,
            ),
          ],
        ),
        ResourceView(
          state: state,
          retry: context.read<VacanciesBloc>().load,
          builder: (vacancies) => Column(
            children: [
              for (final vacancy in vacancies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(vacancy.title),
                        const SizedBox(height: 8),
                        AppBadge(
                          label: vacancy.isOpen
                              ? context.l.open
                              : context.l.closed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${context.money(vacancy.salary.from.amount)} — ${context.money(vacancy.salary.to.amount)}',
                        ),
                        if (vacancy.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(vacancy.description),
                          ),
                        if (vacancy.isOpen)
                          AppButton(
                            label: context.l.closeVacancy,
                            secondary: true,
                            onPressed: state.busy
                                ? null
                                : () => context.read<VacanciesBloc>().closeItem(
                                    vacancy.id,
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
