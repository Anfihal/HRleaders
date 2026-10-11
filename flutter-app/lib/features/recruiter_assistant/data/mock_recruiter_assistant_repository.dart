import '../../../core/di/demo_store.dart';
import '../../../core/error/app_failure.dart';
import '../domain/recruiter_assistant.dart';

final class MockRecruiterAssistantRepository
    implements RecruiterAssistantRepository {
  MockRecruiterAssistantRepository(this.store);

  final DemoStore store;

  @override
  Future<List<RecruiterMessage>> history() async =>
      List.unmodifiable(store.recruiterMessages);

  @override
  Future<RecruiterMessage> ask(String prompt) async {
    final normalized = prompt.trim();
    if (normalized.isEmpty) {
      throw const AppFailure(
        FailureKind.validation,
        'assistant_prompt_required',
      );
    }
    if (normalized.length > 4000) {
      throw const AppFailure(
        FailureKind.validation,
        'assistant_prompt_too_long',
      );
    }
    store.recruiterMessages.add(
      RecruiterMessage(
        id: store.nextId(),
        role: RecruiterMessageRole.user,
        text: normalized,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final response = _response(normalized);
    final message = RecruiterMessage(
      id: store.nextId(),
      role: RecruiterMessageRole.assistant,
      text: response,
      createdAt: DateTime.now().toUtc(),
      demonstration: true,
    );
    store.recruiterMessages.add(message);
    return message;
  }

  @override
  Future<void> clear() async => store.recruiterMessages.clear();

  String _response(String prompt) {
    final request = prompt.toLowerCase();
    final russian = RegExp(r'[\u0400-\u04FF]').hasMatch(prompt);
    if (request.contains('interview') ||
        request.contains('интервью') ||
        request.contains('вопрос')) {
      if (russian) {
        return 'Демонстрационный план — адаптируйте вопросы к роли и оценивайте ответы по единым критериям:\n'
            '1. Расскажите о подходящем проекте и вашем личном вкладе.\n'
            '2. Опишите сложное решение и рассмотренные альтернативы.\n'
            '3. Как вы проверили бы результат и объяснили компромиссы?\n'
            '4. Что вы улучшили бы, если бы выполняли эту работу снова?';
      }
      return 'Demo outline — tailor these questions to the role and evaluate answers against the same criteria for every candidate:\n'
          '1. Describe a relevant project and your personal contribution.\n'
          '2. Walk through a difficult decision and the alternatives considered.\n'
          '3. Explain how you would validate the result and communicate trade-offs.\n'
          '4. What would you improve if you repeated that work?';
    }
    if (request.contains('vacancy') ||
        request.contains('ваканс') ||
        request.contains('requirement') ||
        request.contains('требован')) {
      if (russian) {
        return 'Демонстрационная структура вакансии:\n'
            '• Результат, за который отвечает специалист\n'
            '• Обязательные навыки отдельно от желательного опыта\n'
            '• Типичные задачи и контекст взаимодействия\n'
            '• Проверяемые свидетельства по каждому требованию\n'
            '• Формат работы, диапазон оплаты и этапы интервью\n'
            'Исключите критерии, не связанные с работой.';
      }
      return 'Demo vacancy structure:\n'
          '• Outcome the person will own\n'
          '• Essential skills, separated from optional experience\n'
          '• Typical responsibilities and collaboration context\n'
          '• Evidence you will accept for each requirement\n'
          '• Work format, compensation range, and interview stages\n'
          'Avoid criteria unrelated to the role.';
    }
    if (request.contains('test') ||
        request.contains('результат') ||
        request.contains('оцен') ||
        request.contains('критер')) {
      if (russian) {
        return 'Демонстрационная рамка оценки:\n'
            '1. Свяжите каждый критерий с наблюдаемым ответом или рабочим примером.\n'
            '2. Используйте одну шкалу и фиксируйте свидетельства, а не впечатления.\n'
            '3. Отделяйте подтверждённые результаты от предположений: в демо данных кандидатов нет.\n'
            '4. Обсудите неопределённость и следующий связанный с работой шаг.';
      }
      return 'Demo evaluation framework:\n'
          '1. Link each criterion to an observable answer or work sample.\n'
          '2. Use a consistent rating scale and record evidence, not impressions.\n'
          '3. Separate verified results from assumptions; this demo has no candidate data.\n'
          '4. Discuss uncertainties and agree on a job-relevant follow-up step.';
    }
    if (russian) {
      return 'Демонстрационный план по запросу:\n'
          '• Определите, какое решение о найме должен поддержать ответ.\n'
          '• Выберите связанные с работой свидетельства и единые критерии.\n'
          '• Отметьте неопределённость и наименее затрагивающий кандидата способ её проверить.\n'
          '• Согласуйте следующий шаг и ответственного.\n\n'
          'Данные кандидатов не отправлялись и не анализировались. Уточните запрос: вопросы для интервью, требования вакансии или критерии оценки.';
    }
    return 'Demo planning checklist for this request:\n'
        '• Define the hiring decision this should support.\n'
        '• Choose job-related evidence and consistent criteria.\n'
        '• Identify what remains uncertain and the least intrusive way to learn it.\n'
        '• Agree on the next step and who owns it.\n\n'
        'No candidate data was sent or analyzed. Please refine the request for interview questions, vacancy requirements, or evaluation criteria.';
  }
}

final class UnsupportedRecruiterAssistantRepository
    implements RecruiterAssistantRepository {
  const UnsupportedRecruiterAssistantRepository();

  Never _unsupported() => throw const AppFailure(
    FailureKind.unsupported,
    'assistant_api_unavailable',
  );

  @override
  Future<List<RecruiterMessage>> history() async => _unsupported();

  @override
  Future<RecruiterMessage> ask(String prompt) async => _unsupported();

  @override
  Future<void> clear() async => _unsupported();
}
