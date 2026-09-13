import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';

void main() {
  test('preset weekly capacities can cover a 604-page Madinah mushaf', () {
    final intensive =
        memorizationPlanPresets[MemorizationPlanPace.intensive12Months]!;
    final steady = memorizationPlanPresets[MemorizationPlanPace.steady18Months]!;
    final balanced =
        memorizationPlanPresets[MemorizationPlanPace.balanced24Months]!;

    expect(intensive.weeklyNewPageCapacity * 52, greaterThanOrEqualTo(604));
    expect(steady.weeklyNewPageCapacity * 78, greaterThanOrEqualTo(604));
    expect(balanced.weeklyNewPageCapacity * 104, greaterThanOrEqualTo(604));
  });

  test('every preset reserves the seventh day for consolidation', () {
    for (final preset in memorizationPlanPresets.values) {
      expect(preset.isConsolidationDay(6), isTrue);
      expect(preset.newPagesForPlanDay(6), 0);
      expect(preset.isConsolidationDay(13), isTrue);
    }
  });

  test('18 month plan alternates two-page and one-page study days', () {
    final preset = memorizationPlanPresets[MemorizationPlanPace.steady18Months]!;

    expect(
      List<int>.generate(7, preset.newPagesForPlanDay),
      <int>[2, 1, 1, 2, 1, 1, 0],
    );
  });

  test('daily load keeps seven-day review and 14/30 day checkpoints', () {
    final load = buildMemorizationDailyLoad(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 3,
      olderMemorizedPages: 300,
    );

    expect(load.newPages, 2);
    expect(load.recentReviewDays, 7);
    expect(load.checkpointDays, <int>[14, 30]);
    expect(load.isConsolidationDay, isFalse);
    expect(load.oldReviewPages, 5);
  });

  test('old review is bounded and empty history produces no old review', () {
    final empty = buildMemorizationDailyLoad(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 0,
      olderMemorizedPages: 0,
    );
    final full = buildMemorizationDailyLoad(
      pace: MemorizationPlanPace.intensive12Months,
      planDayIndex: 0,
      olderMemorizedPages: 604,
    );

    expect(empty.oldReviewPages, 0);
    expect(full.oldReviewPages, 10);
  });

  test('learning protocol uses recall and never enables automatic speech scoring', () {
    expect(defaultMemorizationLearningProtocol.readWhileLooking.min, 5);
    expect(defaultMemorizationLearningProtocol.readWhileLooking.max, 10);
    expect(defaultMemorizationLearningProtocol.listenRepeats.min, 3);
    expect(defaultMemorizationLearningProtocol.listenRepeats.max, 5);
    expect(defaultMemorizationLearningProtocol.cleanRecallTarget, 3);
    expect(defaultMemorizationLearningProtocol.connectToPrevious, isTrue);
    expect(
      defaultMemorizationLearningProtocol.automaticSpeechScoringEnabled,
      isFalse,
    );
  });

  test('negative planner input is rejected', () {
    expect(
      () => buildMemorizationDailyLoad(
        pace: MemorizationPlanPace.balanced24Months,
        planDayIndex: -1,
        olderMemorizedPages: 0,
      ),
      throwsArgumentError,
    );
  });
}
