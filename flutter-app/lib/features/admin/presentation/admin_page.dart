import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/admin.dart';
import 'russia_region_map.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, this.promotion = false});
  final bool promotion;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ResourceBloc<AdminSnapshot>, ResourceState<AdminSnapshot>>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(
          title: promotion ? context.l.promotion : context.l.adminTitle,
          actions: [
            AppButton(
              label: context.l.refresh,
              secondary: true,
              onPressed: context.read<ResourceBloc<AdminSnapshot>>().load,
            ),
          ],
        ),
        ResourceView(
          state: state,
          retry: context.read<ResourceBloc<AdminSnapshot>>().load,
          builder: (snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AppStatCard(
                    label: context.l.registeredUsers,
                    value: context.number(snapshot.users),
                  ),
                  AppStatCard(
                    label: context.l.candidates,
                    value: context.number(snapshot.candidates),
                  ),
                  AppStatCard(
                    label: context.l.employer,
                    value: context.number(snapshot.hr),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${context.l.activeVacancies}: ${context.number(snapshot.vacancies)}',
              ),
              const SizedBox(height: 12),
              Text('${context.l.matches}: ${context.number(snapshot.matches)}'),
              const SizedBox(height: 12),
              Text(
                '${context.l.verificationRate}: ${context.percent(snapshot.verificationRate)}',
              ),
              const SizedBox(height: 12),
              Text(
                '${context.l.timeToMatch}: ${snapshot.averageMatchHours == null ? context.l.notAvailable : context.number(snapshot.averageMatchHours!)}',
              ),
              const SizedBox(height: 32),
              AppSectionHeader(title: context.l.regions),
              RussiaRegionMap(regions: snapshot.regions),
            ],
          ),
        ),
      ],
    ),
  );
}
