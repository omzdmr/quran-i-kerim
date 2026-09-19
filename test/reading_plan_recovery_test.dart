import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery.dart';

void main() {
  ActiveReadingPlan plan({Set<int> completedDays = const <int>{}}) =>
      ActiveReadingPlan(
        preset: ReadingPlanPreset.quran30,
        startedAt: DateTime(2026, 9, 16),
        completedDays: completedDays,
      );

  test('catch-up session opens the complete overdue contiguous range', () {
    final active = plan(completedDays: const <int>{1});
    final session = ReadingPlanRecoverySession.catchUp(
      active: active,
      now: DateTime(2026, 9, 20, 21, 30),
    );

    final expectedFirst = readingPlanDay(ReadingPlanPreset.quran30, 2);
    final expectedLast = readingPlanDay(ReadingPlanPreset.quran30, 5);
    expect(session.mode, ReadingPlanRecoveryMode.catchUp);
    expect(session.startPage, expectedFirst.startPage);
    expect(session.endPage, expectedLast.endPage);
    expect(session.catchUpTarget!.dayCount, 4);
    expect(active.completedDays, const <int>{1});
  });

  test('redistributed session resolves the exact page slice for a date', () {
    final active = plan(completedDays: const <int>{1, 2, 3});
    final session = ReadingPlanRecoverySession.redistributed(
      active: active,
      now: DateTime(2026, 9, 20),
      targetEndDate: DateTime(2026, 9, 29),
      forDate: DateTime(2026, 9, 23),
    );

    final proposal = session.redistribution!;
    expect(session.mode, ReadingPlanRecoveryMode.redistribute);
    expect(session.redistributionDayIndex, 3);
    expect(session.startPage, proposal.startPageForDay(3));
    expect(session.endPage, proposal.endPageForDay(3));
    expect(session.pageCount, proposal.pagesForDay(3));
    expect(active.completedDays, const <int>{1, 2, 3});
  });

  test('redistribution rejects dates outside the selected recovery window', () {
    final active = plan();
    expect(
      () => ReadingPlanRecoverySession.redistributed(
        active: active,
        now: DateTime(2026, 9, 20),
        targetEndDate: DateTime(2026, 9, 25),
        forDate: DateTime(2026, 9, 26),
      ),
      throwsRangeError,
    );
  });

  test('completed plan cannot create a recovery session', () {
    final completed = <int>{
      for (var day = 1; day <= ReadingPlanPreset.quran30.durationDays; day++) day,
    };
    final active = plan(completedDays: completed);

    expect(
      () => ReadingPlanRecoverySession.catchUp(
        active: active,
        now: DateTime(2026, 9, 20),
      ),
      throwsStateError,
    );
  });
}
