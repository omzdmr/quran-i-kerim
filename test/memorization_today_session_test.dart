import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_load.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_queue.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_today_plan.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_today_session.dart';

MemorizationTodayPlan _plan({
  List<int> old = const <int>[],
  List<int> recent = const <int>[],
  List<int> checkpoint = const <int>[],
  List<int> consolidation = const <int>[],
  List<int> fresh = const <int>[],
}) {
  return MemorizationTodayPlan(
    elapsedPlanDayIndex: 0,
    effectivePlanDayIndex: 0,
    missedPlanDaysLast7: 0,
    weakRecallCount: 0,
    queue: MemorizationAdaptiveDailyQueue(
      baseQueue: MemorizationDailyQueue(
        newPageCount: fresh.length,
        recentReviewPages: recent,
        checkpointReviewPages: checkpoint,
        oldReviewPages: old,
        consolidationPages: consolidation,
        isConsolidationDay: false,
      ),
      loadDecision: MemorizationAdaptiveLoadDecision(
        baseNewPageCount: fresh.length,
        newPageCount: fresh.length,
        reason: MemorizationAdaptiveLoadReason.normal,
        pressureSignals: 0,
      ),
    ),
    newPages: fresh,
  );
}

void main() {
  test('today session preserves review-first order and removes duplicates', () {
    final plan = _plan(
      old: const <int>[1, 3],
      recent: const <int>[3, 4],
      checkpoint: const <int>[4, 5],
      consolidation: const <int>[5, 6],
      fresh: const <int>[7, 3],
    );

    final items = buildMemorizationTodaySessionItems(plan);

    expect(
      items.map((item) => item.page).toList(),
      plan.studyPages,
    );
    expect(
      items.map((item) => item.kind).toList(),
      const <MemorizationTodaySessionKind>[
        MemorizationTodaySessionKind.oldReview,
        MemorizationTodaySessionKind.oldReview,
        MemorizationTodaySessionKind.recentReview,
        MemorizationTodaySessionKind.checkpointReview,
        MemorizationTodaySessionKind.consolidation,
        MemorizationTodaySessionKind.newMemorization,
      ],
    );
    expect(items.where((item) => item.isReview), hasLength(5));
  });

  test('new memorization remains a non-review session item', () {
    final items = buildMemorizationTodaySessionItems(
      _plan(fresh: const <int>[10, 11]),
    );

    expect(items.map((item) => item.page), <int>[10, 11]);
    expect(items.every((item) => !item.isReview), isTrue);
  });
}
