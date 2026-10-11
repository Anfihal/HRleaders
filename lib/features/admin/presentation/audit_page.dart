import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/admin.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        ResourceBloc<List<AuditEvent>>,
        ResourceState<List<AuditEvent>>
      >(
        builder: (context, state) => ListView(
          children: [
            AppSectionHeader(title: context.l.audit),
            ResourceView(
              state: state,
              retry: context.read<ResourceBloc<List<AuditEvent>>>().load,
              builder: (events) => Column(
                children: [
                  for (final event in events)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Text(
                          '${context.date(event.date)} · ${switch (event.action) {
                            'block' => context.l.block,
                            'unblock' => context.l.unblock,
                            'closeVacancy' => context.l.closeVacancy,
                            _ => context.l.audit,
                          }} · ${event.actorId.value}',
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
