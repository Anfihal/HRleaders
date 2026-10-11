import 'package:flutter_test/flutter_test.dart';
import 'package:hrleaders/core/di/app_dependencies.dart';
import 'package:hrleaders/core/domain/value_objects.dart';
import 'package:hrleaders/features/assessments/domain/assessments.dart';
import 'package:hrleaders/features/recruiter_cjm/domain/recruiter_cjm.dart';

void main() {
  test(
    'recruiter follows candidate, assigns test, and sees scored attempt',
    () async {
      final dependencies = AppDependencies.demo();
      addTearDown(dependencies.dispose);
      final candidateId = EntityId('00000000-0000-4000-8000-000000000200');
      await dependencies.auth.login(
        Email('hr@demo.hrleaders.example'),
        'Demo12345',
      );

      final followed = await dependencies.recruiterCjm.follow(candidateId);
      expect(followed.candidateId, candidateId);
      final tests = await dependencies.assessments.catalog();
      final assignment = await dependencies.recruiterCjm.assign(
        candidateId: candidateId,
        disciplineCode: tests.single.discipline,
        targetGrade: tests.single.grade,
      );
      expect(assignment.status, AssessmentAssignmentStatus.assigned);

      await dependencies.auth.login(
        Email('candidate@demo.hrleaders.example'),
        'Demo12345',
      );
      expect(
        (await dependencies.recruiterCjm.assignments()).single.id,
        assignment.id,
      );
      final attempt = await dependencies.recruiterCjm.startAssignment(
        assignment.id,
      );
      expect(attempt.status, AssessmentStatus.inProgress);

      for (var index = 0; index < tests.single.questions.length; index++) {
        await dependencies.assessments.answer(
          attempt.id,
          index,
          tests.single.questions[index].correctOption!,
        );
      }
      await dependencies.assessments.complete(attempt.id);

      await dependencies.auth.login(
        Email('hr@demo.hrleaders.example'),
        'Demo12345',
      );
      final updatedAssignment =
          (await dependencies.recruiterCjm.assignments()).single;
      expect(updatedAssignment.status, AssessmentAssignmentStatus.scored);
      expect(updatedAssignment.scorePercent, 100);
      final tracked =
          (await dependencies.recruiterCjm.followedCandidates()).single;
      expect(tracked.latestScorePercent, 100);
    },
  );
}
