import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/admin.dart';

class GatewayPage extends StatelessWidget {
  const GatewayPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ResourceBloc<GatewaySnapshot>, ResourceState<GatewaySnapshot>>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(title: context.l.fsp),
        ResourceView(
          state: state,
          retry: context.read<ResourceBloc<GatewaySnapshot>>().load,
          builder: (gateway) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBadge(
                icon: m.Icons.cloud_outlined,
                label:
                    '${context.l.gateway}: ${switch (gateway.status) {
                      GatewayStatus.online => context.l.online,
                      GatewayStatus.degraded => context.l.degraded,
                      GatewayStatus.offline => context.l.offline,
                    }}',
              ),
              const SizedBox(height: 24),
              Text('${context.l.lastSync}: ${context.date(gateway.lastSync)}'),
              const SizedBox(height: 24),
              Text('${context.l.queue}: ${context.number(gateway.queue)}'),
              const SizedBox(height: 24),
              Text(
                '${context.l.requests}: ${context.number(gateway.requests)}',
              ),
              const SizedBox(height: 24),
              Text('${context.l.errors}: ${context.number(gateway.errors)}'),
              const SizedBox(height: 24),
              Text(
                '${context.l.latency}: ${context.number(gateway.latencyMs)}',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
