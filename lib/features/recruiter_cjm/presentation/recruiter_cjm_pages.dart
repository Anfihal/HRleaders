import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../assessments/domain/assessments.dart';
import '../domain/recruiter_cjm.dart';
import 'recruiter_cjm_bloc.dart';

class RecruiterTrackingPage extends StatelessWidget {
  const RecruiterTrackingPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecruiterCjmBloc, RecruiterCjmState>(
        builder: (context, state) {
          final bloc = context.read<RecruiterCjmBloc>();
          if (state.loading &&
              state.followed.isEmpty &&
              state.assignments.isEmpty) {
            return const AppLoadingState();
          }
          return ListView(
            children: [
              AppSectionHeader(
                title: context.l.candidateTracking,
                subtitle: context.l.candidateTrackingDescription,
                actions: [
                  AppBackButton(onPressed: () => context.go('/employer')),
                  AppButton(
                    label: context.l.search,
                    secondary: true,
                    onPressed: () => context.go('/employer/candidates'),
                  ),
                ],
              ),
              if (state.failure != null)
                AppErrorState(failure: state.failure!, retry: bloc.load),
              AppSectionHeader(title: context.l.trackedCandidates),
              if (state.followed.isEmpty)
                AppEmptyState(message: context.l.noTrackedCandidates),
              for (final candidate in state.followed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: AppCard(
                    child: Row(
                      children: [
                        const Icon(m.Icons.person_outline),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(candidate.name),
                              Text(candidate.headline),
                              if (candidate.latestScorePercent != null)
                                Text(
                                  context.l.candidateLatestScore(
                                    candidate.latestScorePercent!.round(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AppIconButton(
                          label: context.l.unfollowCandidate,
                          icon: m.Icons.bookmark_remove_outlined,
                          onPressed: state.saving
                              ? null
                              : () => bloc.unfollow(candidate.candidateId),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.large),
              AppSectionHeader(title: context.l.assessmentAssignments),
              if (state.assignments.isEmpty)
                AppEmptyState(message: context.l.noAssessmentAssignments),
              for (final assignment in state.assignments)
                _AssignmentCard(assignment: assignment),
            ],
          );
        },
      );
}

class CandidateRecruitingActions extends StatelessWidget {
  const CandidateRecruitingActions({super.key, required this.candidateId});

  final EntityId candidateId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecruiterCjmBloc, RecruiterCjmState>(
        builder: (context, state) {
          final bloc = context.read<RecruiterCjmBloc>();
          final tracked = state.followed.any(
            (item) => item.candidateId == candidateId,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.failure != null)
                AppErrorState(failure: state.failure!, retry: bloc.load),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  AppButton(
                    label: tracked
                        ? context.l.unfollowCandidate
                        : context.l.followCandidate,
                    secondary: tracked,
                    icon: tracked
                        ? m.Icons.bookmark_remove_outlined
                        : m.Icons.bookmark_add_outlined,
                    busy: state.saving,
                    onPressed: () => tracked
                        ? bloc.unfollow(candidateId)
                        : bloc.follow(candidateId),
                  ),
                  AppButton(
                    label: context.l.assignAssessment,
                    secondary: true,
                    icon: m.Icons.assignment_outlined,
                    onPressed: state.tests.isEmpty
                        ? null
                        : () => _showAssignmentChoices(context, state.tests),
                  ),
                ],
              ),
            ],
          );
        },
      );

  Future<void> _showAssignmentChoices(
    BuildContext context,
    List<AssessmentTest> tests,
  ) async {
    final bloc = context.read<RecruiterCjmBloc>();
    await appDialog<void>(
      context,
      title: context.l.assignAssessment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final test in tests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: AppButton(
                label: '${test.title} · ${test.discipline} / ${test.grade}',
                secondary: true,
                onPressed: () async {
                  await bloc.assign(
                    candidateId: candidateId,
                    disciplineCode: test.discipline,
                    targetGrade: test.grade,
                  );
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class CandidateAssessmentAssignments extends StatelessWidget {
  const CandidateAssessmentAssignments({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecruiterCjmBloc, RecruiterCjmState>(
        builder: (context, state) {
          final assignments = state.assignments;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(title: context.l.assessmentAssignments),
              if (state.loading && assignments.isEmpty)
                const AppLoadingState()
              else if (assignments.isEmpty)
                AppEmptyState(message: context.l.noAssessmentAssignments)
              else
                for (final assignment in assignments)
                  _AssignmentCard(assignment: assignment, candidateView: true),
            ],
          );
        },
      );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, this.candidateView = false});

  final AssessmentAssignment assignment;
  final bool candidateView;

  String _status(BuildContext context) => switch (assignment.status) {
    AssessmentAssignmentStatus.assigned => context.l.assignmentStatusAssigned,
    AssessmentAssignmentStatus.inProgress => context.l.assessmentInProgress,
    AssessmentAssignmentStatus.submitted => context.l.assessmentSubmitted,
    AssessmentAssignmentStatus.scored => context.l.assessmentCompleted,
    AssessmentAssignmentStatus.expired => context.l.assessmentExpired,
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecruiterCjmBloc>();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidateView
                  ? '${assignment.disciplineCode} · ${assignment.targetGrade}'
                  : assignment.candidateName,
              style: AppTypography.heading(context, size: 17),
            ),
            if (!candidateView)
              Text('${assignment.disciplineCode} · ${assignment.targetGrade}'),
            Text(_status(context)),
            if (assignment.scorePercent != null)
              Text(
                context.l.candidateLatestScore(
                  assignment.scorePercent!.round(),
                ),
              ),
            if (candidateView &&
                assignment.status == AssessmentAssignmentStatus.assigned)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.medium),
                child: AppButton(
                  label: context.l.assessmentStart,
                  icon: m.Icons.play_arrow,
                  busy: context.select(
                    (RecruiterCjmBloc bloc) => bloc.state.saving,
                  ),
                  onPressed: () async {
                    final attempt = await bloc.startAssignment(assignment.id);
                    if (context.mounted && attempt != null) {
                      context.go('/candidate/assessments/${attempt.id.value}');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
