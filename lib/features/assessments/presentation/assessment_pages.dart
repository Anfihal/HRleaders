import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/assessments.dart';
import 'assessment_bloc.dart';
import '../../recruiter_cjm/presentation/recruiter_cjm_pages.dart';

class AssessmentsPage extends StatelessWidget {
  const AssessmentsPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AssessmentBloc, AssessmentState>(
    builder: (context, state) {
      final bloc = context.read<AssessmentBloc>();
      if (state.loading && state.tests.isEmpty) return const AppLoadingState();
      if (state.failure != null && state.tests.isEmpty) {
        return AppErrorState(failure: state.failure!, retry: bloc.load);
      }
      return ListView(
        children: [
          AppSectionHeader(
            title: context.l.assessments,
            subtitle: context.l.demoAssessmentNote,
            actions: [
              AppBackButton(onPressed: () => context.go('/candidate/profile')),
            ],
          ),
          const CandidateAssessmentAssignments(),
          if (state.failure != null)
            AppErrorState(failure: state.failure!, retry: bloc.load),
          if (state.tests.isEmpty)
            AppEmptyState(message: context.l.noAssessments),
          for (final test in state.tests) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: AppTypography.heading(context, size: 18),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(test.description),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      AppChip(label: context.referenceLabel(test.discipline)),
                      if (test.durationMinutes != null)
                        AppChip(
                          label: context.l.assessmentMinutes(
                            test.durationMinutes!,
                          ),
                        ),
                      AppChip(label: context.referenceLabel(test.grade)),
                      if (test.employerAssigned)
                        AppChip(label: context.l.employerAssignedTest),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _TestAction(test: test, attempts: state.attempts),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
          ],
          AppSectionHeader(title: context.l.assessmentHistory),
          if (state.attempts.isEmpty)
            AppEmptyState(message: context.l.noAssessmentAttempts),
          for (final attempt in state.attempts)
            _AttemptTile(attempt: attempt, tests: state.tests),
          const SizedBox(height: AppSpacing.large),
          _AchievementSummary(attempts: state.attempts),
        ],
      );
    },
  );
}

class _TestAction extends StatelessWidget {
  const _TestAction({required this.test, required this.attempts});
  final AssessmentTest test;
  final List<AssessmentAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final active = attempts
        .where(
          (item) =>
              item.testId == test.id &&
              item.status == AssessmentStatus.inProgress,
        )
        .firstOrNull;
    final bloc = context.read<AssessmentBloc>();
    return AppButton(
      label: active == null
          ? context.l.assessmentStart
          : context.l.assessmentResume,
      icon: active == null ? m.Icons.play_arrow : m.Icons.play_circle_outline,
      busy: context.select((AssessmentBloc bloc) => bloc.state.saving),
      onPressed: () async {
        if (active != null) {
          context.go('/candidate/assessments/${active.id.value}');
          return;
        }
        await bloc.start(test.id);
        final attempt = bloc.state.selectedAttempt;
        if (context.mounted && attempt != null) {
          context.go('/candidate/assessments/${attempt.id.value}');
        }
      },
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt, required this.tests});
  final AssessmentAttempt attempt;
  final List<AssessmentTest> tests;

  @override
  Widget build(BuildContext context) {
    final test = tests.where((item) => item.id == attempt.testId).firstOrNull;
    final title = test?.title ?? attempt.testId;
    final label = switch (attempt.status) {
      AssessmentStatus.inProgress => context.l.assessmentInProgress,
      AssessmentStatus.submitted => context.l.assessmentSubmitted,
      AssessmentStatus.completed => context.l.assessmentCompleted,
      AssessmentStatus.expired => context.l.assessmentExpired,
    };
    final reportAvailable =
        attempt.status == AssessmentStatus.submitted ||
        attempt.status == AssessmentStatus.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: AppCard(
        child: Row(
          children: [
            const Icon(m.Icons.assignment_outlined),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text('${context.date(attempt.startedAt)} · $label'),
                ],
              ),
            ),
            AppIconButton(
              label: reportAvailable
                  ? context.l.assessmentOpenReport
                  : context.l.assessmentContinue,
              icon: reportAvailable
                  ? m.Icons.article_outlined
                  : m.Icons.play_arrow,
              onPressed: attempt.status == AssessmentStatus.expired
                  ? null
                  : () => context.go(
                      reportAvailable
                          ? '/candidate/assessments/${attempt.id.value}/report'
                          : '/candidate/assessments/${attempt.id.value}',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSummary extends StatelessWidget {
  const _AchievementSummary({required this.attempts});
  final List<AssessmentAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final completed = attempts
        .where((item) => item.status == AssessmentStatus.completed)
        .toList();
    final started = attempts.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: context.l.achievements),
          _AchievementRow(
            icon: m.Icons.flag_outlined,
            title: context.l.achievementStarted,
            description: context.l.achievementStartedDescription,
            date: started ? attempts.last.startedAt : null,
          ),
          const SizedBox(height: AppSpacing.medium),
          _AchievementRow(
            icon: m.Icons.verified_outlined,
            title: context.l.achievementCompleted,
            description: context.l.achievementCompletedDescription,
            date: completed.isEmpty ? null : completed.last.completedAt,
          ),
          if (completed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            Text(context.l.assessmentCompletionCount(completed.length)),
          ],
          const SizedBox(height: AppSpacing.medium),
          Text(context.l.fspAchievementsNote),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.date,
  });
  final IconData icon;
  final String title;
  final String description;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon),
      const SizedBox(width: AppSpacing.medium),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(description),
            Text(
              date == null
                  ? context.l.achievementInProgress
                  : context.l.dateReceived(context.date(date!)),
            ),
          ],
        ),
      ),
    ],
  );
}

class AssessmentAttemptPage extends StatefulWidget {
  const AssessmentAttemptPage({super.key, required this.attemptId});
  final String attemptId;

  @override
  State<AssessmentAttemptPage> createState() => _AssessmentAttemptPageState();
}

class _AssessmentAttemptPageState extends State<AssessmentAttemptPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssessmentBloc>().openAttempt(EntityId(widget.attemptId));
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AssessmentBloc, AssessmentState>(
    builder: (context, state) {
      final attempt = state.selectedAttempt;
      if (state.loading || attempt == null) {
        return state.failure == null
            ? const AppLoadingState()
            : AppErrorState(
                failure: state.failure!,
                retry: () => context.read<AssessmentBloc>().openAttempt(
                  EntityId(widget.attemptId),
                ),
              );
      }
      final test = state.tests
          .where((item) => item.id == attempt.testId)
          .firstOrNull;
      if (test == null) return const AppLoadingState();
      final attemptQuestions = attempt.questionIds.isEmpty
          ? test.questions
          : attempt.questionIds
                .map(
                  (id) => test.questions
                      .where((question) => question.id == id)
                      .firstOrNull,
                )
                .whereType<AssessmentQuestion>()
                .toList();
      final attemptTest = test.copyWith(questions: attemptQuestions);
      if (attempt.status != AssessmentStatus.inProgress) {
        return ListView(
          children: [
            AppSectionHeader(
              title: test.title,
              subtitle: attempt.status == AssessmentStatus.submitted
                  ? context.l.assessmentSubmitted
                  : attempt.status == AssessmentStatus.expired
                  ? context.l.assessmentExpired
                  : context.l.assessmentCompleted,
              actions: [
                AppBackButton(
                  onPressed: () => context.go('/candidate/assessments'),
                ),
              ],
            ),
            if (attempt.status == AssessmentStatus.submitted)
              Text(context.l.assessmentPendingScore),
            if (attempt.status != AssessmentStatus.expired)
              AppButton(
                label: context.l.assessmentOpenReport,
                onPressed: () => context.go(
                  '/candidate/assessments/${attempt.id.value}/report',
                ),
              ),
          ],
        );
      }
      final nextIndex = attempt.answers.indexWhere((answer) => answer == null);
      final index = nextIndex < 0
          ? attemptTest.questions.length - 1
          : nextIndex;
      final question = attemptTest.questions[index];
      final answered = attempt.answers.where((value) => value != null).length;
      final bloc = context.read<AssessmentBloc>();
      return ListView(
        children: [
          AppSectionHeader(
            title: test.title,
            subtitle: context.l.assessmentProgress(
              answered,
              attemptTest.questions.length,
            ),
            actions: [
              AppBackButton(
                onPressed: () => context.go('/candidate/assessments'),
              ),
            ],
          ),
          m.LinearProgressIndicator(
            value: answered / attemptTest.questions.length,
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l.assessmentQuestion(
                    index + 1,
                    attemptTest.questions.length,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  question.prompt,
                  style: AppTypography.heading(context, size: 18),
                ),
                const SizedBox(height: AppSpacing.medium),
                for (var option = 0; option < question.options.length; option++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: AppButton(
                      label: question.options[option],
                      secondary: attempt.answers[index] != option,
                      onPressed: state.saving
                          ? null
                          : () => context.read<AssessmentBloc>().answer(
                              index,
                              option,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.failure != null)
            AppErrorState(
              failure: state.failure!,
              retry: () => context.read<AssessmentBloc>().answer(
                index,
                attempt.answers[index] ?? 0,
              ),
            ),
          const SizedBox(height: AppSpacing.large),
          AppButton(
            label: context.l.assessmentFinish,
            icon: m.Icons.check,
            busy: state.saving,
            onPressed: answered == attemptTest.questions.length
                ? () async {
                    await bloc.complete();
                    if (!context.mounted) return;
                    final report = bloc.state.report;
                    if (report != null) {
                      context.go(
                        '/candidate/assessments/${attempt.id.value}/report',
                      );
                    }
                  }
                : null,
          ),
        ],
      );
    },
  );
}

class AssessmentReportPage extends StatefulWidget {
  const AssessmentReportPage({super.key, required this.attemptId});
  final String attemptId;

  @override
  State<AssessmentReportPage> createState() => _AssessmentReportPageState();
}

class _AssessmentReportPageState extends State<AssessmentReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssessmentBloc>().loadReport(EntityId(widget.attemptId));
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AssessmentBloc, AssessmentState>(
    builder: (context, state) {
      final report = state.report;
      if (state.loading || report == null) {
        return state.failure == null
            ? const AppLoadingState()
            : AppErrorState(
                failure: state.failure!,
                retry: () => context.read<AssessmentBloc>().loadReport(
                  EntityId(widget.attemptId),
                ),
              );
      }
      return ListView(
        children: [
          AppSectionHeader(
            title: context.l.assessmentReport,
            subtitle: report.test.title,
            actions: [
              AppBackButton(
                onPressed: () => context.go('/candidate/assessments'),
              ),
            ],
          ),
          if (report.awaitingScore)
            AppCard(child: Text(context.l.assessmentPendingScore)),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              if (report.percent != null)
                AppStatCard(
                  label: context.l.assessmentScore,
                  value: '${report.percent}%',
                ),
              if (report.correctAnswers != null)
                AppStatCard(
                  label: context.l.assessmentCorrectAnswers,
                  value:
                      '${report.correctAnswers}/${report.test.questions.length}',
                ),
              if (report.elapsed != null)
                AppStatCard(
                  label: context.l.assessmentElapsed,
                  value: context.l.assessmentMinutes(
                    (report.elapsed!.inSeconds / 60).ceil(),
                  ),
                ),
            ],
          ),
          if (!report.awaitingScore && report.attempt.completedAt != null) ...[
            const SizedBox(height: AppSpacing.large),
            Text(
              '${context.l.assessmentCompleted}: ${context.date(report.attempt.completedAt!)}',
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          AppSectionHeader(title: context.l.assessmentStrengths),
          if (!report.hasSkillBreakdown)
            Text(context.l.assessmentSkillsUnavailable)
          else if (report.strengths.isEmpty)
            AppEmptyState(message: context.l.assessmentNoStrengths),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: report.strengths
                .map((skill) => AppChip(label: skill))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.medium),
          AppSectionHeader(title: context.l.assessmentDevelopmentAreas),
          if (!report.hasSkillBreakdown)
            Text(context.l.assessmentSkillsUnavailable)
          else if (report.developmentAreas.isEmpty)
            Text(context.l.assessmentNoDevelopmentAreas),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: report.developmentAreas
                .map((skill) => AppChip(label: skill))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.large),
          if (context.read<AssessmentBloc>().repository.supportsReflection)
            AppButton(
              label: context.l.assessmentReflection,
              icon: m.Icons.edit_note,
              secondary: report.attempt.reflection != null,
              onPressed: () => context.go(
                '/candidate/assessments/${report.attempt.id.value}/reflection',
              ),
            ),
          const SizedBox(height: AppSpacing.small),
          AppButton(
            label: context.l.assessmentNextTests,
            secondary: true,
            onPressed: () => context.go('/candidate/assessments'),
          ),
        ],
      );
    },
  );
}

class AssessmentReflectionPage extends StatefulWidget {
  const AssessmentReflectionPage({super.key, required this.attemptId});
  final String attemptId;

  @override
  State<AssessmentReflectionPage> createState() =>
      _AssessmentReflectionPageState();
}

class _AssessmentReflectionPageState extends State<AssessmentReflectionPage> {
  late final fields = List.generate(5, (_) => TextEditingController());
  static const questions = [
    'reflectionStrength',
    'reflectionChallenge',
    'reflectionLearned',
    'reflectionImprove',
    'reflectionNextStep',
  ];
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<AssessmentBloc>().repository.supportsReflection) {
        context.read<AssessmentBloc>().loadReport(EntityId(widget.attemptId));
      }
    });
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  String _label(BuildContext context, String key) => switch (key) {
    'reflectionStrength' => context.l.reflectionStrength,
    'reflectionChallenge' => context.l.reflectionChallenge,
    'reflectionLearned' => context.l.reflectionLearned,
    'reflectionImprove' => context.l.reflectionImprove,
    _ => context.l.reflectionNextStep,
  };

  void _populate(AssessmentAttempt attempt) {
    if (initialized) return;
    final reflection = attempt.reflection;
    if (reflection != null) {
      final values = [
        reflection.strength,
        reflection.challenge,
        reflection.learned,
        reflection.improve,
        reflection.nextStep,
      ];
      for (var i = 0; i < fields.length; i++) {
        fields[i].text = values[i];
      }
    }
    initialized = true;
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AssessmentBloc, AssessmentState>(
        builder: (context, state) {
          if (!context.read<AssessmentBloc>().repository.supportsReflection) {
            return ListView(
              children: [
                AppSectionHeader(
                  title: context.l.assessmentReflection,
                  actions: [
                    AppBackButton(
                      onPressed: () => context.go(
                        '/candidate/assessments/${widget.attemptId}/report',
                      ),
                    ),
                  ],
                ),
                AppEmptyState(message: context.l.unsupported),
              ],
            );
          }
          final report = state.report;
          if (report == null) {
            return state.failure == null
                ? const AppLoadingState()
                : AppErrorState(
                    failure: state.failure!,
                    retry: () => context.read<AssessmentBloc>().loadReport(
                      EntityId(widget.attemptId),
                    ),
                  );
          }
          _populate(report.attempt);
          return ListView(
            children: [
              AppSectionHeader(
                title: context.l.assessmentReflection,
                subtitle: report.test.title,
                actions: [
                  AppBackButton(
                    onPressed: () => context.go(
                      '/candidate/assessments/${widget.attemptId}/report',
                    ),
                  ),
                ],
              ),
              for (var i = 0; i < fields.length; i++) ...[
                AppTextField(
                  label: _label(context, questions[i]),
                  controller: fields[i],
                  lines: 3,
                  enabled: !state.saving,
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (state.failure != null)
                AppErrorState(failure: state.failure!, retry: _save),
              if (state.saved)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: Text(context.l.assessmentReflectionSaved),
                ),
              AppButton(
                label: context.l.reflectionSave,
                icon: m.Icons.save_outlined,
                busy: state.saving,
                onPressed: _save,
              ),
            ],
          );
        },
      );

  void _save() => context.read<AssessmentBloc>().saveReflection(
    strength: fields[0].text,
    challenge: fields[1].text,
    learned: fields[2].text,
    improve: fields[3].text,
    nextStep: fields[4].text,
  );
}

class CandidateAssessmentSummary extends StatelessWidget {
  const CandidateAssessmentSummary({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AssessmentBloc, AssessmentState>(
        builder: (context, state) {
          if (state.loading && state.attempts.isEmpty) {
            return const AppLoadingState();
          }
          final completed = state.attempts
              .where((item) => item.status == AssessmentStatus.completed)
              .toList();
          final active = state.attempts
              .where((item) => item.status == AssessmentStatus.inProgress)
              .firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                title: context.l.assessments,
                subtitle: context.l.assessmentSummary(completed.length),
                actions: [
                  AppButton(
                    label: context.l.assessmentOpenCatalog,
                    onPressed: () => context.go('/candidate/assessments'),
                  ),
                  if (active != null)
                    AppButton(
                      label: context.l.assessmentContinue,
                      secondary: true,
                      onPressed: () => context.go(
                        '/candidate/assessments/${active.id.value}',
                      ),
                    ),
                ],
              ),
              const CandidateAssessmentAssignments(),
              if (state.failure != null)
                AppErrorState(
                  failure: state.failure!,
                  retry: context.read<AssessmentBloc>().load,
                ),
              if (state.attempts.isEmpty)
                AppEmptyState(message: context.l.noAssessmentAttempts),
              for (final attempt in completed.take(3))
                _AttemptTile(attempt: attempt, tests: state.tests),
              const SizedBox(height: AppSpacing.medium),
              _AchievementSummary(attempts: state.attempts),
              const SizedBox(height: AppSpacing.large),
            ],
          );
        },
      );
}
