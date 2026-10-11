import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/candidates.dart';
import 'profile_bloc.dart';
import 'profile_content.dart';
import 'profile_form.dart';
import '../../../features/assessments/presentation/assessment_pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: BlocBuilder<ProfileBloc, ResourceState<Candidate>>(
      builder: (context, state) => ResourceView(
        state: state,
        retry: context.read<ProfileBloc>().load,
        builder: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: context.l.profile,
              actions: [
                AppButton(
                  label: context.l.edit,
                  secondary: true,
                  onPressed: state.busy
                      ? null
                      : () => appDialog(
                          context,
                          title: context.l.edit,
                          child: MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<ProfileBloc>(),
                              ),
                              BlocProvider(
                                create: (_) =>
                                    context
                                        .read<AppDependencies>()
                                        .dictionariesBloc()
                                      ..load(),
                              ),
                            ],
                            child: ProfileForm(profile: profile),
                          ),
                        ),
                ),
                AppButton(
                  label: context.l.syncFsp,
                  onPressed: context.read<ProfileBloc>().sync,
                  busy: state.busy,
                ),
              ],
            ),
            ProfileContent(profile: profile),
            const SizedBox(height: 32),
            const CandidateAssessmentSummary(),
          ],
        ),
      ),
    ),
  );
}
