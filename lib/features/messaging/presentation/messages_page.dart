import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/messaging.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        ResourceBloc<List<Conversation>>,
        ResourceState<List<Conversation>>
      >(
        builder: (context, state) => ListView(
          children: [
            AppSectionHeader(
              title: context.l.messages,
              subtitle: context.l.messagingUnavailable,
            ),
            ResourceView(
              state: state,
              retry: context.read<ResourceBloc<List<Conversation>>>().load,
              builder: (_) => const SizedBox.shrink(),
            ),
          ],
        ),
      );
}
