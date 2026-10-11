import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/components/app_components.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../../hiring/presentation/send_offer_form.dart';
import '../../recruiter_cjm/presentation/recruiter_cjm_pages.dart';
import '../domain/candidates.dart';
import 'profile_content.dart';

class CandidateDetailPage extends StatelessWidget {
  const CandidateDetailPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: BlocBuilder<ResourceBloc<Candidate>, ResourceState<Candidate>>(
      builder: (context, state) => ResourceView(
        state: state,
        retry: context.read<ResourceBloc<Candidate>>().load,
        builder: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: context.l.viewProfile,
              actions: [
                AppBackButton(
                  onPressed: () => context.go('/employer/candidates'),
                ),
                AppButton(
                  label: context.l.sendOffer,
                  onPressed: () {
                    final deps = context.read<AppDependencies>();
                    appDialog<bool>(
                      context,
                      title: context.l.sendOffer,
                      child: MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (_) => deps.vacanciesBloc()..load(),
                          ),
                          BlocProvider(create: (_) => deps.sendOfferBloc()),
                        ],
                        child: SendOfferForm(candidateId: profile.id),
                      ),
                    );
                  },
                ),
              ],
            ),
            ProfileContent(profile: profile),
            const SizedBox(height: 24),
            CandidateRecruitingActions(candidateId: profile.id),
          ],
        ),
      ),
    ),
  );
}
