import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_timeline.dart';

void main() {
  group('effectiveMemorizationPlanDayIndex', () {
    test('pauses progression for distinct missed days before today', () {
      expect(
        effectiveMemorizationPlanDayIndex(
          elapsedPlanDayIndex: 6,
          missedPlanDays: const [1, 3],
        ),
        4,
      );
    });

    test('does not count today or future days as already missed', () {
      expect(
        effectiveMemorizationPlanDayIndex(
          elapsedPlanDayIndex: 4,
          missedPlanDays: const [4, 5],
        ),
        4,
      );
    });

    test('counts duplicate missed-day entries only once', () {
      expect(
        effectiveMemorizationPlanDayIndex(
          elapsedPlanDayIndex: 5,
          missedPlanDays: const [1, 1, 2],
        ),
        3,
      );
    });

    test('rejects negative elapsed or missed plan-day indexes', () {
      expect(
        () => effectiveMemorizationPlanDayIndex(
          elapsedPlanDayIndex: -1,
          missedPlanDays: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => effectiveMemorizationPlanDayIndex(
          elapsedPlanDayIndex: 2,
          missedPlanDays: const [-1],
        ),
        throwsArgumentError,
      );
    });
  });
}
