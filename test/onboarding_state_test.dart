import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_modern/src/features/onboarding/application/onboarding_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('onboarding is incomplete on a fresh install', () async {
    expect(await OnboardingState.isCompleted(), isFalse);
  });

  test('markCompleted persists the onboarding gate locally', () async {
    await OnboardingState.markCompleted();

    expect(await OnboardingState.isCompleted(), isTrue);
  });
}
