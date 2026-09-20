import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/lesson_visual_flow.dart';

void main() {
  const labels = LearnLessonVisualLabels(
    previous: 'Previous',
    next: 'Next',
    finish: 'Finish',
    correctFeedback: 'Correct',
    incorrectFeedback: 'Incorrect',
    backToLessons: 'Back',
    continueInQuran: 'Continue',
  );

  testWidgets('resume starts at requested step and quiz gates forward navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearnLessonVisualFlow(
          lessonTitle: 'Lesson',
          initialStepIndex: 1,
          labels: labels,
          steps: <LearnLessonVisualStep>[
            LearnLessonVisualStep(
              id: 'intro',
              type: LearnLessonVisualStepType.introduction,
              title: 'Intro',
            ),
            LearnLessonVisualStep(
              id: 'quiz',
              type: LearnLessonVisualStepType.quiz,
              title: 'Quiz',
              quizOptions: <String>['A', 'B'],
              correctQuizIndex: 0,
            ),
            LearnLessonVisualStep(
              id: 'completion',
              type: LearnLessonVisualStepType.completion,
              title: 'Done',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Intro'), findsNothing);
    expect(find.text('Done'), findsNothing);

    final nextButton = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);

    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
  });
}
