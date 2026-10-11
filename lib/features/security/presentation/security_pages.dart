import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/security.dart';
import 'notifications_bloc.dart';

String notificationLabel(BuildContext context, NotificationKind kind) =>
    switch (kind) {
      NotificationKind.offerReceived => context.l.offerReceived,
      NotificationKind.offerAccepted => context.l.offerAccepted,
      NotificationKind.offerRejected => context.l.offerRejected,
      NotificationKind.matchCreated => context.l.matchCreated,
      NotificationKind.verificationCompleted => context.l.verificationCompleted,
      NotificationKind.securityAlert => context.l.securityAlert,
    };

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ResourceBloc<SecuritySnapshot>, ResourceState<SecuritySnapshot>>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(
          title: context.l.security,
          subtitle: context.l.privacy,
        ),
        ResourceView(
          state: state,
          retry: context.read<ResourceBloc<SecuritySnapshot>>().load,
          builder: (snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSecurityBadge(),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: context.l.sessions,
                subtitle:
                    '${context.l.currentSession}: ${context.number(snapshot.activeSessions)}',
              ),
              AppSectionHeader(
                title: context.l.loginHistory,
                subtitle: context.date(snapshot.lastLogin),
              ),
              AppSectionHeader(title: context.l.securityEvents),
              for (final event in snapshot.events)
                Text(
                  '${notificationLabel(context, event.kind)} · ${context.date(event.date)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSectionHeader(
          title: context.l.twoFactor,
          subtitle: context.l.twoFactorUnavailable,
        ),
      ],
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationsBloc, ResourceState<List<AppNotification>>>(
        builder: (context, state) => ListView(
          children: [
            AppSectionHeader(title: context.l.notifications),
            ResourceView(
              state: state,
              retry: context.read<NotificationsBloc>().load,
              builder: (items) => Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(notificationLabel(context, item.kind)),
                            Text(context.date(item.date)),
                            if (!item.read)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: AppButton(
                                  label: context.l.markRead,
                                  secondary: true,
                                  onPressed: state.busy
                                      ? null
                                      : () => context
                                            .read<NotificationsBloc>()
                                            .read(item.id),
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
