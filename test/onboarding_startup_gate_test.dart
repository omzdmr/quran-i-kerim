import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_modern/src/features/onboarding/application/onboarding_gate.dart';
import 'package:quran_modern/src/features/onboarding/presentation/onboarding_startup_gate.dart';

void main() {
  testWidgets('shows onboarding when persisted state is incomplete',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStartupGate(
          gate: OnboardingGate(isCompleted: () async => false),
          onboarding: const Text('onboarding'),
          app: const Text('app'),
        ),
      ),
    );

    expect(find.text('onboarding'), findsNothing);
    expect(find.text('app'), findsNothing);

    await tester.pump();

    expect(find.text('onboarding'), findsOneWidget);
    expect(find.text('app'), findsNothing);
  });

  testWidgets('shows app when persisted onboarding is complete',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStartupGate(
          gate: OnboardingGate(isCompleted: () async => true),
          onboarding: const Text('onboarding'),
          app: const Text('app'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('onboarding'), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
