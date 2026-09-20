import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_adaptive_load.dart';

void main() {
  group('adaptMemorizationNewPageLoad', () {
    test('keeps planned load when review pressure is clear', () {
      final decision = adaptMemorizationNewPageLoad(
        baseNewPageCount: 2,
        isConsolidationDay: false,
        recentReviewPageCount: 4,
        checkpointReviewPageCount: 1,
        oldReviewPageCount: 3,
        weakRecallCount: 1,
        missedPlanDaysLast7: 0,
      );

      expect(decision.newPageCount, 2);
      expect(decision.reason, MemorizationAdaptiveLoadReason.normal);
      expect(decision.pressureSignals, 0);
      expect(decision.isReduced, isFalse);
    });

    test('reduces a two-page day under moderate review pressure', () {
      final decision = adaptMemorizationNewPageLoad(
        baseNewPageCount: 2,
        isConsolidationDay: false,
        recentReviewPageCount: 5,
        checkpointReviewPageCount: 1,
        oldReviewPageCount: 3,
        weakRecallCount: 1,
        missedPlanDaysLast7: 0,
      );

      expect(decision.newPageCount, 1);
      expect(decision.reason, MemorizationAdaptiveLoadReason.reviewPressure);
      expect(decision.pressureSignals, 1);
      expect(decision.isReduced, isTrue);
      expect(decision.pausesNewMemorization, isFalse);
    });

    test('pauses a one-page day when multiple review signals accumulate', () {
      final decision = adaptMemorizationNewPageLoad(
        baseNewPageCount: 1,
        isConsolidationDay: false,
        recentReviewPageCount: 5,
        checkpointReviewPageCount: 2,
        oldReviewPageCount: 0,
        weakRecallCount: 0,
        missedPlanDaysLast7: 0,
      );

      expect(decision.newPageCount, 0);
      expect(decision.reason, MemorizationAdaptiveLoadReason.recovery);
      expect(decision.pressureSignals, 2);
      expect(decision.pausesNewMemorization, isTrue);
    });

    test('strong review debt pauses new memorization immediately', () {
      final decision = adaptMemorizationNewPageLoad(
        baseNewPageCount: 2,
        isConsolidationDay: false,
        recentReviewPageCount: 8,
        checkpointReviewPageCount: 0,
        oldReviewPageCount: 0,
        weakRecallCount: 0,
        missedPlanDaysLast7: 0,
      );

      expect(decision.newPageCount, 0);
      expect(decision.reason, MemorizationAdaptiveLoadReason.recovery);
      expect(decision.pausesNewMemorization, isTrue);
    });

    test('consolidation day never schedules new pages', () {
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
  });
}
