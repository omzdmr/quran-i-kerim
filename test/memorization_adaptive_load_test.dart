import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_load.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_queue.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';

void main() {
  test('healthy review state preserves the selected pace ceiling', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 2,
      isConsolidationDay: false,
      recentReviewPageCount: 2,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 1,
      weakRecallCount: 0,
      missedPlanDaysLast7: 0,
    );

    expect(decision.newPageCount, 2);
    expect(decision.reason, MemorizationAdaptiveLoadReason.normal);
    expect(decision.isReduced, isFalse);
  });

  test('moderate review pressure trims a two-page day to one page', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 2,
      isConsolidationDay: false,
      recentReviewPageCount: 2,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 0,
      weakRecallCount: 2,
      missedPlanDaysLast7: 0,
    );

    expect(decision.newPageCount, 1);
    expect(decision.reason, MemorizationAdaptiveLoadReason.reviewPressure);
    expect(decision.isReduced, isTrue);
  });

  test('heavy old review pressure pauses new memorization', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 2,
      isConsolidationDay: false,
      recentReviewPageCount: 0,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 8,
      weakRecallCount: 0,
      missedPlanDaysLast7: 0,
    );

    expect(decision.newPageCount, 0);
    expect(decision.reason, MemorizationAdaptiveLoadReason.recovery);
    expect(decision.pausesNewMemorization, isTrue);
  });

  test('two simultaneous pressure signals can pause a one-page plan', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 1,
      isConsolidationDay: false,
      recentReviewPageCount: 5,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 0,
      weakRecallCount: 2,
      missedPlanDaysLast7: 0,
    );

    expect(decision.newPageCount, 0);
    expect(decision.reason, MemorizationAdaptiveLoadReason.recovery);
    expect(decision.pausesNewMemorization, isTrue);
  });

  test('two missed plan days force a recovery day', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 2,
      isConsolidationDay: false,
      recentReviewPageCount: 0,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 0,
      weakRecallCount: 0,
      missedPlanDaysLast7: 2,
    );

    expect(decision.newPageCount, 0);
    expect(decision.reason, MemorizationAdaptiveLoadReason.recovery);
  });

  test('consolidation day never schedules new memorization', () {
    final decision = adaptMemorizationNewPageLoad(
      baseNewPageCount: 2,
      isConsolidationDay: true,
      recentReviewPageCount: 0,
      checkpointReviewPageCount: 0,
      oldReviewPageCount: 0,
      weakRecallCount: 0,
      missedPlanDaysLast7: 0,
    );

    expect(decision.newPageCount, 0);
    expect(decision.reason, MemorizationAdaptiveLoadReason.consolidation);
  });

  test('adaptive queue keeps all review work while reducing only new load', () {
    final now = DateTime(2026, 9, 13);
    final queue = buildAdaptiveMemorizationDailyQueue(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 0,
      now: now,
      weakRecallCount: 2,
      memorizedAtByPage: <int, DateTime>{
        1: now.subtract(const Duration(days: 2)),
        2: now.subtract(const Duration(days: 14)),
        3: now.subtract(const Duration(days: 40)),
      },
    );

    expect(queue.baseNewPageCount, 2);
    expect(queue.newPageCount, 1);
    expect(queue.recentReviewPages, <int>[1]);
    expect(queue.checkpointReviewPages, <int>[2]);
    expect(queue.oldReviewPages, <int>[3]);
    expect(queue.isNewLoadReduced, isTrue);
  });

  test('adaptive inputs reject negative counters', () {
    expect(
      () => adaptMemorizationNewPageLoad(
        baseNewPageCount: 1,
        isConsolidationDay: false,
        recentReviewPageCount: 0,
        checkpointReviewPageCount: 0,
        oldReviewPageCount: -1,
        weakRecallCount: 0,
        missedPlanDaysLast7: 0,
      ),
      throwsArgumentError,
    );
  });
}
