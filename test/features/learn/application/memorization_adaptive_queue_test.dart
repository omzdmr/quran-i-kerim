import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_queue.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';

void main() {
  test('adaptive queue preserves review work while reducing new pages', () {
    final now = DateTime(2026, 9, 16, 12);
    final queue = buildAdaptiveMemorizationDailyQueue(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 1,
      now: now,
      memorizedAtByPage: <int, DateTime>{
        1: now.subtract(const Duration(days: 2)),
        2: now.subtract(const Duration(days: 14)),
        3: now.subtract(const Duration(days: 40)),
      },
      weakRecallCount: 3,
      missedPlanDaysLast7: 2,
    );

    expect(queue.recentReviewPages, contains(1));
    expect(queue.checkpointReviewPages, contains(2));
    expect(queue.oldReviewPages, contains(3));
    expect(queue.newPageCount, lessThan(queue.baseNewPageCount));
  });

  test('adaptive queue excludes work already completed on the same date', () {
    final now = DateTime(2026, 9, 16, 23, 30);
    final queue = buildAdaptiveMemorizationDailyQueue(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 1,
      now: now,
      memorizedAtByPage: <int, DateTime>{
        1: DateTime(2026, 9, 16, 1),
        2: now.subtract(const Duration(days: 2)),
      },
      lastReviewedAtByPage: <int, DateTime>{
        2: DateTime(2026, 9, 16, 2),
      },
    );

    expect(queue.recentReviewPages, isEmpty);
    expect(queue.checkpointReviewPages, isEmpty);
    expect(queue.oldReviewPages, isEmpty);
  });
}
