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

  test('stopping an active plan keeps saved and completed history', () async {
    await store.toggleSaved(ReadingPlanPreset.quran90);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 16));

    final after = await store.stopActive();

    expect(after.active, isNull);
    expect(after.savedPresetIds, <String>{'quran90'});
  });
}
