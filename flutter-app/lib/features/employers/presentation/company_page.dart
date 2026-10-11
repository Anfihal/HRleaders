import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../auth/presentation/auth_bloc.dart';

/// Displays the company field already returned by the identity contract.
class CompanyPage extends StatelessWidget {
  const CompanyPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => ListView(
      children: [
        AppSectionHeader(
          title: context.l.company,
          subtitle: context.l.companyReadOnly,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.session?.user.company ?? context.l.empty),
              const SizedBox(height: 16),
              Text(state.session?.user.name ?? ''),
              Text(state.session?.user.email.value ?? ''),
            ],
          ),
        ),
      ],
    ),
  );
}
