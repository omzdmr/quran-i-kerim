import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_gate.dart';

void main() {
  test('shows onboarding when completion state is false', () async {
    final gate = OnboardingGate(isCompleted: () async => false);

    expect(await gate.shouldShowOnboarding(), isTrue);
  });

  test('skips onboarding when completion state is true', () async {
    final gate = OnboardingGate(isCompleted: () async => true);

    expect(await gate.shouldShowOnboarding(), isFalse);
  });
}
