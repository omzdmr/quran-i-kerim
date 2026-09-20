import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ReadingPlanStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('started plan survives a fresh store instance', () async {
    await store.start(
      ReadingPlanPreset.quran90,
      now: DateTime(2026, 9, 16, 23, 40),
    );

    final loaded = await const ReadingPlanStore().load();
    expect(loaded.active?.preset, ReadingPlanPreset.quran90);
    expect(loaded.active?.startedAt, DateTime(2026, 9, 16));
    expect(loaded.active?.nextDayNumber, 1);
    expect(loaded.active?.isPaused, isFalse);
    expect(loaded.active?.pausedDays, 0);
  });

  test('completing a day advances without depending on calendar time', () async {
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));

    final after = await store.completeNextDay(now: DateTime(2026, 9, 20));

    expect(after.active?.completedDays, <int>{1});
    expect(after.active?.nextDayNumber, 2);
  });

  test('saved presets persist independently from the active plan', () async {
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));
    await store.toggleSaved(ReadingPlanPreset.quran365);

    final loaded = await store.load();
    expect(loaded.active?.preset, ReadingPlanPreset.quran30);
    expect(loaded.savedPresetIds, <String>{'quran365'});
  });

  test('finishing the final day archives the plan and clears active state', () async {
    final completedDays = <int>{for (var day = 1; day < 30; day++) day};
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":{"preset":"quran30","startedAt":"2026-08-18","completedDays":${completedDays.toList()}},"saved":[],"completed":[]}',
    });

    final after = await store.completeNextDay(now: DateTime(2026, 9, 16));

    expect(after.active, isNull);
    expect(after.completed, hasLength(1));
    expect(after.completed.single.preset, ReadingPlanPreset.quran30);
    expect(after.completed.single.completedAt, DateTime(2026, 9, 16));
  });

  test('corrupted and unknown persisted values are sanitized', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":{"preset":"unknown","startedAt":"bad","completedDays":[1,999]},"saved":["quran90","bad"],"completed":[{"preset":"bad"}]}',
    });

    final loaded = await store.load();

    expect(loaded.active, isNull);
    expect(loaded.savedPresetIds, <String>{'quran90'});
    expect(loaded.completed, isEmpty);
  });

  test('persisted day lists are deduplicated, bounded, and normalized', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":{"preset":"quran30","startedAt":"2026-09-16T23:40:00+08:00","completedDays":[1,"1",2,0,-1,30,31,"bad"]},"saved":[],"completed":[]}',
    });

    final loaded = await store.load();

    expect(loaded.active?.startedAt, DateTime(2026, 9, 16));
    expect(loaded.active?.completedDays, <int>{1, 2, 30});
    expect(loaded.active?.nextDayNumber, 3);
    expect(loaded.active?.pausedAt, isNull);
    expect(loaded.active?.pausedDays, 0);
  });

  test('malformed persisted json recovers as an empty snapshot', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey: '{not-json',
    });

    final loaded = await store.load();

    expect(loaded.active, isNull);
    expect(loaded.savedPresetIds, isEmpty);
    expect(loaded.completed, isEmpty);
  });

  test('completed history ignores invalid rows without silently truncating archive', () async {
    final rows = <String>[
      for (var day = 1; day <= 22; day++)
        '{"preset":"quran30","startedAt":"2026-08-01","completedAt":"2026-09-${day.toString().padLeft(2, '0')}"}',
      '{"preset":"unknown","startedAt":"2026-08-01","completedAt":"2026-09-01"}',
      '{"preset":"quran30","startedAt":"bad","completedAt":"2026-09-01"}',
    ];
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":null,"saved":[],"completed":[${rows.join(',')}]}'
    });

    final loaded = await store.load();

    expect(loaded.completed, hasLength(22));
    expect(loaded.completed.first.completedAt, DateTime(2026, 9, 1));
    expect(loaded.completed.last.completedAt, DateTime(2026, 9, 22));
  });

  test('stopping an active plan keeps saved and completed history', () async {
    await store.toggleSaved(ReadingPlanPreset.quran90);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));

    final after = await store.stopActive();

    expect(after.active, isNull);
    expect(after.savedPresetIds, <String>{'quran90'});
  });

  test('pausing persists the pause date and blocks completion', () async {
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));
    final paused = await store.pauseActive(now: DateTime(2026, 9, 18, 14));
    final attempted = await store.completeNextDay(now: DateTime(2026, 9, 19));
    final loaded = await const ReadingPlanStore().load();

    expect(paused.active?.pausedAt, DateTime(2026, 9, 18));
    expect(paused.active?.isPaused, isTrue);
    expect(attempted.active?.completedDays, isEmpty);
    expect(loaded.active?.pausedAt, DateTime(2026, 9, 18));
  });

  test('resuming accumulates full paused days and keeps original start', () async {
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));
    await store.pauseActive(now: DateTime(2026, 9, 18));
    final resumed = await store.resumeActive(now: DateTime(2026, 9, 25));
    final reloaded = await const ReadingPlanStore().load();

    expect(resumed.active?.isPaused, isFalse);
    expect(resumed.active?.startedAt, DateTime(2026, 9, 16));
    expect(resumed.active?.pausedDays, 7);
    expect(reloaded.active?.pausedDays, 7);
    expect(
      reloaded.active?.scheduleStatus(DateTime(2026, 9, 25)).calendarDayNumber,
      3,
    );
  });

  test('invalid pause metadata is sanitized without breaking older plans', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":{"preset":"quran30","startedAt":"2026-09-16","completedDays":[],"pausedAt":"2026-09-10","pausedDays":-7},"saved":[],"completed":[]}',
    });

    final loaded = await store.load();

    expect(loaded.active?.pausedAt, isNull);
    expect(loaded.active?.pausedDays, 0);
    expect(loaded.active?.startedAt, DateTime(2026, 9, 16));
  });

  test('yearly khatm target persists across plan mutations and can be cleared', () async {
    await store.setYearlyKhatmTarget(3);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 20));
    await store.toggleSaved(ReadingPlanPreset.quran90);

    var loaded = await const ReadingPlanStore().load();
    expect(loaded.yearlyKhatmTarget, 3);

    await store.setYearlyKhatmTarget(null);
    loaded = await const ReadingPlanStore().load();
    expect(loaded.yearlyKhatmTarget, isNull);
  });

  test('yearly khatm target rejects invalid values and sanitizes persisted data', () async {
    await expectLater(store.setYearlyKhatmTarget(0), throwsRangeError);
    await expectLater(store.setYearlyKhatmTarget(100), throwsRangeError);

    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":null,"saved":[],"completed":[],"yearlyKhatmTarget":150}',
    });

    final loaded = await store.load();
    expect(loaded.yearlyKhatmTarget, isNull);
  });

  test('yearly khatm progress counts only completions in the selected year', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingPlanStore.preferenceKey:
          '{"active":null,"saved":[],"yearlyKhatmTarget":3,"completed":['
          '{"preset":"quran30","startedAt":"2025-12-01","completedAt":"2025-12-30"},'
          '{"preset":"quran30","startedAt":"2026-01-01","completedAt":"2026-01-30"},'
          '{"preset":"quran90","startedAt":"2026-03-01","completedAt":"2026-05-29"}'
          ']}',
    });

    final loaded = await store.load();
    expect(loaded.completedInYear(2025), 1);
    expect(loaded.completedInYear(2026), 2);
    expect(loaded.remainingForYear(2026), 1);
    expect(loaded.remainingForYear(2025), 2);
  });

}
