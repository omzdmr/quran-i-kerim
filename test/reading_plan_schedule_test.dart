import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';

void main() {
  ActiveReadingPlan plan({
    Set<int> completedDays = const <int>{},
    DateTime? startedAt,
  }) {
    return ActiveReadingPlan(
      preset: ReadingPlanPreset.quran30,
      startedAt: startedAt ?? DateTime(2026, 9, 16),
      completedDays: completedDays,
    );
  }

  test('start day is on track before todays portion is completed', () {
    final status = plan().scheduleStatus(DateTime(2026, 9, 16, 23, 59));

    expect(status.calendarDayNumber, 1);
    expect(status.expectedCompletedBeforeToday, 0);
    expect(status.behindByDays, 0);
    expect(status.aheadByDays, 0);
    expect(status.isOnTrack, isTrue);
    expect(status.scheduledEndDate, DateTime(2026, 10, 15));
  });

  test('an unfinished previous day becomes overdue on the next date', () {
    final status = plan().scheduleStatus(DateTime(2026, 9, 17));

    expect(status.calendarDayNumber, 2);
    expect(status.expectedCompletedBeforeToday, 1);
    expect(status.behindByDays, 1);
    expect(status.isBehind, isTrue);
  });

  test('completing the previous day keeps the plan on track', () {
    final status = plan(
      completedDays: const <int>{1},
    ).scheduleStatus(DateTime(2026, 9, 17));

    expect(status.completedPrefixDays, 1);
    expect(status.behindByDays, 0);
    expect(status.aheadByDays, 0);
    expect(status.isOnTrack, isTrue);
  });

  test('reading beyond todays scheduled portion is reported as ahead', () {
    final status = plan(
      completedDays: const <int>{1, 2},
    ).scheduleStatus(DateTime(2026, 9, 16));

    expect(status.calendarDayNumber, 1);
    expect(status.completedPrefixDays, 2);
    expect(status.aheadByDays, 1);
    expect(status.isAhead, isTrue);
  });

  test('today itself is not counted overdue before it ends', () {
    final status = plan(
      completedDays: const <int>{1, 2},
    ).scheduleStatus(DateTime(2026, 9, 18, 23, 59));

    expect(status.calendarDayNumber, 3);
    expect(status.expectedCompletedBeforeToday, 2);
    expect(status.behindByDays, 0);
  });

  test('schedule clamps after the planned end date and keeps overdue debt', () {
    final status = plan(
      completedDays: const <int>{1, 2, 3},
    ).scheduleStatus(DateTime(2026, 11, 20));

    expect(status.calendarDayNumber, 30);
    expect(status.expectedCompletedBeforeToday, 30);
    expect(status.behindByDays, 27);
  });

  test('completed plan remains on track after its scheduled end date', () {
    final completedDays = <int>{
      for (var day = 1; day <= ReadingPlanPreset.quran30.durationDays; day++) day,
    };
    final status = plan(
      completedDays: completedDays,
    ).scheduleStatus(DateTime(2026, 11, 20));

    expect(status.calendarDayNumber, 30);
    expect(status.expectedCompletedBeforeToday, 30);
    expect(status.completedPrefixDays, 30);
    expect(status.behindByDays, 0);
    expect(status.aheadByDays, 0);
    expect(status.isOnTrack, isTrue);
  });

  test('a future start date never invents overdue work', () {
    final status = plan(
      startedAt: DateTime(2026, 9, 20),
    ).scheduleStatus(DateTime(2026, 9, 16));

    expect(status.calendarDayNumber, 1);
    expect(status.expectedCompletedBeforeToday, 0);
    expect(status.behindByDays, 0);
  });

  test('isolated future completion does not skip an earlier missing day', () {
    final active = plan(completedDays: const <int>{1, 2, 30});

    expect(active.completedPrefixDays, 2);
    expect(active.progress, closeTo(2 / 30, 0.000001));
    final status = active.scheduleStatus(DateTime(2026, 9, 20));
    expect(status.completedPrefixDays, 2);
    expect(status.behindByDays, 2);
  });
}
