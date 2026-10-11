import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/components/app_data_table.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../../hiring/domain/hiring.dart';
import 'admin_vacancies_bloc.dart';

class AdminVacanciesPage extends StatelessWidget {
  const AdminVacanciesPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AdminVacanciesBloc, ResourceState<List<Vacancy>>>(
    builder: (context, state) {
      final bloc = context.read<AdminVacanciesBloc>();
      Widget action(Vacancy v) => AppButton(
        label: context.l.closeVacancy,
        secondary: true,
        onPressed: !v.isOpen || state.busy
            ? null
            : () => bloc.closeVacancy(v.id),
      );
      return ListView(
        children: [
          AppSectionHeader(
            title: context.l.vacancies,
            actions: [
              AppButton(
                label: context.l.refresh,
                secondary: true,
                onPressed: bloc.load,
              ),
            ],
          ),
          ResourceView(
            state: state,
            retry: bloc.load,
            builder: (vacancies) => AppDataTable<Vacancy>(
              items: vacancies,
              columns: [
                context.l.vacancyTitle,
                context.l.salary,
                context.l.active,
                context.l.closeVacancy,
              ],
              cells: (v) => [
                Text(v.title),
                Text(
                  '${context.money(v.salary.from.amount)} – ${context.money(v.salary.to.amount)}',
                ),
                Text(v.isOpen ? context.l.open : context.l.closed),
                action(v),
              ],
              mobileCard: (v) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title),
                    const SizedBox(height: 12),
                    Text(v.isOpen ? context.l.open : context.l.closed),
                    const SizedBox(height: 12),
                    action(v),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
