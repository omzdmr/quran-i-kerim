import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_timeline.dart';

void main() {
  test('missed days pause plan progression instead of stacking new work', () {
    expect(
      effectiveMemorizationPlanDayIndex(
        elapsedPlanDayIndex: 5,
        missedPlanDays: const <int>[1, 3],
      ),
      3,
    );
  });

  test('today is not counted as missed before it has elapsed', () {
    expect(
      effectiveMemorizationPlanDayIndex(
        elapsedPlanDayIndex: 5,
        missedPlanDays: const <int>[5],
      ),
      5,
    );
  });

  test('duplicate missed days only pause the plan once', () {
    expect(
      effectiveMemorizationPlanDayIndex(
        elapsedPlanDayIndex: 4,
        missedPlanDays: const <int>[1, 1, 2],
      ),
      2,
    );
  });

  test('invalid planner input is rejected', () {
    expect(
      () => effectiveMemorizationPlanDayIndex(
        elapsedPlanDayIndex: -1,
        missedPlanDays: const <int>[],
      ),
      throwsArgumentError,
    );
    expect(
      () => effectiveMemorizationPlanDayIndex(
        elapsedPlanDayIndex: 2,
        missedPlanDays: const <int>[-1],
      ),
      throwsArgumentError,
    );
  });
}
