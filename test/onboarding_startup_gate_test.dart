import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_gate.dart';
import 'package:quran_i_kerim/src/features/onboarding/presentation/onboarding_startup_gate.dart';

void main() {
  testWidgets('shows onboarding when first-run gate resolves true',
      (tester) async {
    final gate = OnboardingGate(isCompleted: () async => false);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStartupGate(
          gate: gate,
          onboarding: const Text('onboarding'),
          app: const Text('app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('onboarding'), findsOneWidget);
    expect(find.text('app'), findsNothing);
  });

  testWidgets('shows app when onboarding is already completed', (tester) async {
    final gate = OnboardingGate(isCompleted: () async => true);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStartupGate(
          gate: gate,
          onboarding: const Text('onboarding'),
          app: const Text('app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('app'), findsOneWidget);
    expect(find.text('onboarding'), findsNothing);
  });
}
