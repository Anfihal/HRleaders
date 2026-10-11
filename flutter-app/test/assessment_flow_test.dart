import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/core/error/app_failure.dart';
import 'package:hrleaders/features/assessments/domain/assessments.dart';
import 'package:hrleaders/features/recruiter_assistant/domain/recruiter_assistant.dart';

void main() {
  test(
    'mock assessment persists answers, report, reflection, and attempts',
    () async {
      final dependencies = AppDependencies.demo();
      addTearDown(dependencies.dispose);
      await dependencies.auth.login(
        Email('candidate@demo.hrleaders.example'),
        'Demo12345',
      );
      final repository = dependencies.assessments;
      final test = (await repository.catalog()).single;
      final first = await repository.start(test.id);
      expect(await repository.start(test.id), same(first));
      await expectLater(
        repository.complete(first.id),
        throwsA(isA<AppFailure>()),
      );

      for (var index = 0; index < test.questions.length; index++) {
        await repository.answer(
          first.id,
          index,
          test.questions[index].correctOption!,
        );
      }
      final result = await repository.complete(first.id);
      expect(result.percent, 100);
      expect(result.correctAnswers, test.questions.length);
      expect(result.attempt.status, AssessmentStatus.completed);
      expect((await repository.report(first.id)).attempt.id, first.id);

      final reflection = await repository.saveReflection(
        first.id,
        strength: 'Reasoning',
        challenge: 'Time pressure',
        learned: 'I explain complexity clearly.',
        improve: 'Practice graph search.',
        nextStep: 'Review algorithms.',
      );
      expect(reflection.reflection?.nextStep, 'Review algorithms.');
      expect((await repository.report(first.id)).attempt.reflection, isNotNull);
      expect((await repository.attempts()).length, 1);

      final second = await repository.start(test.id);
      expect(second.id, isNot(first.id));
      expect((await repository.attempts()).length, 2);
      expect((await repository.report(first.id)).percent, 100);
    },
  );

  test('mock assessment reports only measured skill results', () async {
    final dependencies = AppDependencies.demo();
    addTearDown(dependencies.dispose);
    await dependencies.auth.login(
      Email('candidate@demo.hrleaders.example'),
      'Demo12345',
    );
    final repository = dependencies.assessments;
    final test = (await repository.catalog()).single;
    final attempt = await repository.start(test.id);
    await repository.answer(attempt.id, 0, 1);
    await repository.answer(attempt.id, 1, 0);
    await repository.answer(attempt.id, 2, 0);
    final report = await repository.complete(attempt.id);
    expect(report.percent, 67);
    expect(report.strengths, contains('Reasoning about loops'));
    expect(report.developmentAreas, contains('Data structures'));

    await dependencies.auth.login(
      Email('hr@demo.hrleaders.example'),
      'Demo12345',
    );
    expect(await repository.attempts(), isEmpty);
    await expectLater(
      repository.report(attempt.id),
      throwsA(isA<AppFailure>()),
    );
  });

  test(
    'recruiter assistant keeps explicitly marked demo replies in session',
    () async {
      final dependencies = AppDependencies.demo();
      addTearDown(dependencies.dispose);
      final repository = dependencies.recruiterAssistant;
      final answer = await repository.ask(
        'Prepare interview questions for a software engineer',
      );
      expect(answer.role, RecruiterMessageRole.assistant);
      expect(answer.demonstration, isTrue);
      expect(answer.text, contains('personal contribution'));
      expect((await repository.history()).length, 2);
      await repository.clear();
      expect(await repository.history(), isEmpty);
    },
  );
}
