import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/recruiter_assistant.dart';
import 'assistant_bloc.dart';

class RecruiterAssistantPage extends StatefulWidget {
  const RecruiterAssistantPage({super.key});

  @override
  State<RecruiterAssistantPage> createState() => _RecruiterAssistantPageState();
}

class _RecruiterAssistantPageState extends State<RecruiterAssistantPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final prompt = _controller.text;
    if (prompt.trim().isEmpty) return;
    context.read<RecruiterAssistantBloc>().send(prompt);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecruiterAssistantBloc, RecruiterAssistantState>(
        builder: (context, state) {
          final bloc = context.read<RecruiterAssistantBloc>();
          return ListView(
            children: [
              AppSectionHeader(
                title: context.l.recruiterAssistantTitle,
                subtitle: context.l.recruiterAssistantDescription,
                actions: [
                  AppBackButton(onPressed: () => context.go('/employer')),
                  AppButton(
                    label: context.l.recruiterAssistantClear,
                    secondary: true,
                    onPressed: state.sending || state.messages.isEmpty
                        ? null
                        : bloc.clear,
                  ),
                ],
              ),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(m.Icons.info_outline),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: Text(context.l.recruiterAssistantDemo)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              if (state.messages.isEmpty)
                AppEmptyState(message: context.l.recruiterAssistantEmpty),
              for (final message in state.messages)
                _MessageCard(message: message),
              if (state.sending)
                AppCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: s.CircularProgressIndicator(),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Text(context.l.recruiterAssistantLoading),
                    ],
                  ),
                ),
              if (state.failure != null)
                AppErrorState(failure: state.failure!, retry: bloc.retry),
              const SizedBox(height: AppSpacing.medium),
              Text(context.l.recruiterAssistantExamples),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  AppButton(
                    label: context.l.recruiterAssistantInterview,
                    secondary: true,
                    onPressed: state.sending
                        ? null
                        : () {
                            _controller.text =
                                context.l.recruiterAssistantInterviewPrompt;
                            _send();
                          },
                  ),
                  AppButton(
                    label: context.l.recruiterAssistantVacancy,
                    secondary: true,
                    onPressed: state.sending
                        ? null
                        : () {
                            _controller.text =
                                context.l.recruiterAssistantVacancyPrompt;
                            _send();
                          },
                  ),
                  AppButton(
                    label: context.l.recruiterAssistantCriteria,
                    secondary: true,
                    onPressed: state.sending
                        ? null
                        : () {
                            _controller.text =
                                context.l.recruiterAssistantCriteriaPrompt;
                            _send();
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextField(
                label: context.l.recruiterAssistantPrompt,
                controller: _controller,
                lines: 3,
                enabled: !state.sending,
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppButton(
                label: context.l.recruiterAssistantSend,
                icon: m.Icons.send_outlined,
                busy: state.sending,
                onPressed: state.sending ? null : _send,
              ),
            ],
          );
        },
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final RecruiterMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == RecruiterMessageRole.assistant;
    final scheme = s.Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAssistant
                      ? m.Icons.auto_awesome_outlined
                      : m.Icons.person_outline,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    isAssistant
                        ? context.l.recruiterAssistantTitle
                        : context.l.recruiterAssistantYou,
                  ),
                ),
                if (message.demonstration)
                  Text(
                    context.l.recruiterAssistantDemoBadge,
                    style: TextStyle(color: scheme.mutedForeground),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(message.text),
          ],
        ),
      ),
    );
  }
}
