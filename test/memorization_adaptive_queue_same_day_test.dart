import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_queue.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';

void main() {
  test('adaptive queue does not reschedule work completed today', () {
    final now = DateTime(2026, 9, 14, 18);
    final queue = buildAdaptiveMemorizationDailyQueue(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 1,
      now: now,
      memorizedAtByPage: <int, DateTime>{
        1: now,
        2: now.subtract(const Duration(days: 2)),
        3: now.subtract(const Duration(days: 14)),
        4: now.subtract(const Duration(days: 40)),
      },
      lastReviewedAtByPage: <int, DateTime>{
        2: now.subtract(const Duration(hours: 2)),
        3: now.subtract(const Duration(hours: 3)),
        4: now.subtract(const Duration(hours: 4)),
      },
    );

    expect(queue.recentReviewPages, isEmpty);
    expect(queue.checkpointReviewPages, isEmpty);
    expect(queue.oldReviewPages, isEmpty);
    expect(queue.consolidationPages, isEmpty);
  });
}
