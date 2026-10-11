import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../domain/recruiter_assistant.dart';

final class RecruiterAssistantState {
  const RecruiterAssistantState({
    this.messages = const [],
    this.sending = false,
    this.failure,
    this.lastPrompt,
  });

  final List<RecruiterMessage> messages;
  final bool sending;
  final AppFailure? failure;
  final String? lastPrompt;
}

final class RecruiterAssistantBloc extends Cubit<RecruiterAssistantState> {
  RecruiterAssistantBloc(this.repository)
    : super(const RecruiterAssistantState());

  final RecruiterAssistantRepository repository;

  Future<void> load() async {
    try {
      final messages = await repository.history();
      if (!isClosed) emit(RecruiterAssistantState(messages: messages));
    } on AppFailure catch (error) {
      if (!isClosed) emit(RecruiterAssistantState(failure: error));
    }
  }

  Future<void> send(String prompt) async {
    if (state.sending) return;
    final text = prompt.trim();
    emit(
      RecruiterAssistantState(
        messages: state.messages,
        sending: true,
        lastPrompt: text,
      ),
    );
    try {
      await repository.ask(text);
      final messages = await repository.history();
      if (!isClosed) emit(RecruiterAssistantState(messages: messages));
    } on AppFailure catch (error) {
      if (!isClosed) {
        emit(
          RecruiterAssistantState(
            messages: state.messages,
            failure: error,
            lastPrompt: text,
          ),
        );
      }
    }
  }

  Future<void> retry() async {
    final prompt = state.lastPrompt;
    if (prompt != null) await send(prompt);
  }

  Future<void> clear() async {
    if (state.sending) return;
    try {
      await repository.clear();
      if (!isClosed) emit(const RecruiterAssistantState());
    } on AppFailure catch (error) {
      if (!isClosed) {
        emit(RecruiterAssistantState(messages: state.messages, failure: error));
      }
    }
  }
}
