import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('memorization plan pace and start date stay local', () async {
    const store = MemorizationPlanStore();

    final saved = await store.save(
      pace: MemorizationPlanPace.steady18Months,
      startedAt: DateTime(2026, 9, 13, 21, 45),
    );
    final restored = await store.load();

    expect(saved.pace, MemorizationPlanPace.steady18Months);
    expect(saved.startedAt, DateTime(2026, 9, 13));
    expect(saved.missedPlanDays, isEmpty);
    expect(restored.pace, MemorizationPlanPace.steady18Months);
    expect(restored.startedAt, DateTime(2026, 9, 13));
    expect(restored.missedPlanDays, isEmpty);
    expect(restored.hasPlan, isTrue);
  });

  test('missed plan days stay local, sorted, and deduplicated', () async {
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.intensive12Months,
      startedAt: DateTime(2026, 9, 1),
      missedPlanDays: <int>[8, 2, 8, 5],
    );

    expect((await store.load()).missedPlanDays, <int>[2, 5, 8]);

    final updated = await store.saveMissedPlanDays(<int>[12, 3, 3]);
    expect(updated, <int>[3, 12]);
    expect((await store.load()).missedPlanDays, <int>[3, 12]);
  });

  test('corrupted missed-day values are ignored instead of inventing work', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_pace_v1': MemorizationPlanPace.steady18Months.name,
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['4', '-1', 'bad', '4', '9'],
    });

    final restored = await const MemorizationPlanStore().load();
    expect(restored.missedPlanDays, <int>[4, 9]);
    expect(restored.hasPlan, isTrue);
  });

  test('negative missed plan day cannot be persisted', () async {
    expect(
      () => const MemorizationPlanStore().saveMissedPlanDays(<int>[0, -1]),
      throwsArgumentError,
    );
  });

  test('empty and corrupted plan state does not invent a plan', () async {
    const store = MemorizationPlanStore();
    expect((await store.load()).hasPlan, isFalse);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_pace_v1': 'unknown',
      'memorization_plan_started_at_v1': 'not-a-date',
    });

    final restored = await store.load();
    expect(restored.pace, isNull);
    expect(restored.startedAt, isNull);
    expect(restored.missedPlanDays, isEmpty);
    expect(restored.hasPlan, isFalse);
  });

  test('clearing a plan removes persisted plan and missed-day state', () async {
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.balanced24Months,
      startedAt: DateTime(2026, 9, 13),
      missedPlanDays: <int>[1, 2],
    );

    await store.clear();
    final restored = await store.load();

    expect(restored.pace, isNull);
    expect(restored.startedAt, isNull);
    expect(restored.missedPlanDays, isEmpty);
    expect(restored.hasPlan, isFalse);
  });
}
