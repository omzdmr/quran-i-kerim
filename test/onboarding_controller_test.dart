import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_controller.dart';

void main() {
  test('walks the bounded onboarding steps and completes only at the end', () async {
    var completions = 0;
    final controller = OnboardingController(
      markCompleted: () async => completions += 1,
    );

    expect(controller.step, OnboardingStep.language);
    expect(controller.progress, 0.25);
    expect(controller.canGoBack, isFalse);

    expect(await controller.next(), isFalse);
    expect(controller.step, OnboardingStep.translation);
    expect(await controller.next(), isFalse);
    expect(controller.step, OnboardingStep.readingGoal);
    expect(await controller.next(), isFalse);
    expect(controller.step, OnboardingStep.reciter);
    expect(controller.isLastStep, isTrue);
    expect(completions, 0);

    expect(await controller.next(), isTrue);
    expect(completions, 1);
  });

  test('back never moves before the first step', () async {
    final controller = OnboardingController(markCompleted: () async {});

    controller.back();
    expect(controller.step, OnboardingStep.language);

    await controller.next();
    controller.back();
    expect(controller.step, OnboardingStep.language);
  });
}
