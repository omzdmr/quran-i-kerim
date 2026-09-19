import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_redistribution.dart';

void main() {
  ActiveReadingPlan plan({Set<int> completedDays = const <int>{}}) {
    return ActiveReadingPlan(
      preset: ReadingPlanPreset.quran30,
      startedAt: DateTime(2026, 9, 16),
      completedDays: completedDays,
    );
  }

  test('redistributes only unfinished pages across user-selected window', () {
    final active = plan(completedDays: const <int>{1, 2, 3, 4, 5});
    final proposal = proposeReadingPlanRedistribution(
      active: active,
      now: DateTime(2026, 9, 20, 18, 30),
      targetEndDate: DateTime(2026, 10, 14, 23, 59),
    );

    expect(proposal, isNotNull);
    final next = readingPlanDay(ReadingPlanPreset.quran30, 6);
    expect(proposal!.startPage, next.startPage);
    expect(proposal.endPage, madinahMushafPageCount);
    expect(proposal.availableDays, 25);
    expect(
      proposal.basePagesPerDay * proposal.availableDays + proposal.extraPageDays,
      proposal.remainingPages,
    );
  });

  test('daily slices are contiguous and cover every remaining page exactly', () {
    final proposal = proposeReadingPlanRedistribution(
      active: plan(completedDays: const <int>{1}),
      now: DateTime(2026, 9, 20),
      targetEndDate: DateTime(2026, 9, 29),
    )!;

    expect(proposal.startPageForDay(0), proposal.startPage);
    for (var day = 1; day < proposal.availableDays; day++) {
      expect(
        proposal.startPageForDay(day),
        proposal.endPageForDay(day - 1) + 1,
      );
    }
    expect(
      proposal.endPageForDay(proposal.availableDays - 1),
      madinahMushafPageCount,
    );
  });

  test('earliest days receive at most one extra page', () {
    final proposal = proposeReadingPlanRedistribution(
      active: plan(completedDays: const <int>{1, 2}),
      now: DateTime(2026, 9, 20),
      targetEndDate: DateTime(2026, 10, 3),
    )!;

    for (var day = 0; day < proposal.availableDays; day++) {
      final expected = proposal.basePagesPerDay +
          (day < proposal.extraPageDays ? 1 : 0);
      expect(proposal.pagesForDay(day), expected);
    }
  });

  test('same-day recovery assigns all remaining pages without dropping work', () {
    final proposal = proposeReadingPlanRedistribution(
      active: plan(completedDays: const <int>{1, 2, 3}),
      now: DateTime(2026, 9, 20),
      targetEndDate: DateTime(2026, 9, 20),
    )!;

    expect(proposal.availableDays, 1);
    expect(proposal.pagesForDay(0), proposal.remainingPages);
    expect(proposal.endPageForDay(0), madinahMushafPageCount);
  });

  test('rejects a target date in the past', () {
    expect(
      () => proposeReadingPlanRedistribution(
        active: plan(),
        now: DateTime(2026, 9, 20),
        targetEndDate: DateTime(2026, 9, 19),
      ),
      throwsArgumentError,
    );
  });

  test('completed plan has no redistribution proposal', () {
    final completed = <int>{
      for (var day = 1; day <= ReadingPlanPreset.quran30.durationDays; day++) day,
    };
    expect(
      proposeReadingPlanRedistribution(
        active: plan(completedDays: completed),
        now: DateTime(2026, 9, 20),
        targetEndDate: DateTime(2026, 10, 20),
      ),
      isNull,
    );
  });
}
