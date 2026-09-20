import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save persists pace, date-only start, and normalized missed days', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationPlanStore();

    final saved = await store.save(
      pace: MemorizationPlanPace.steady18Months,
      startedAt: DateTime(2026, 9, 15, 18, 45),
      missedPlanDays: const <int>[4, 1, 4, 2],
    );
    final reloaded = await store.load();

    expect(saved.pace, MemorizationPlanPace.steady18Months);
    expect(saved.startedAt, DateTime(2026, 9, 15));
    expect(saved.missedPlanDays, <int>[1, 2, 4]);
    expect(reloaded.pace, saved.pace);
    expect(reloaded.startedAt, saved.startedAt);
    expect(reloaded.missedPlanDays, saved.missedPlanDays);
  });

  test('saveMissedPlanDays updates an existing plan without changing it', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.balanced24Months,
      startedAt: DateTime(2026, 9, 1),
    );

    final savedDays = await store.saveMissedPlanDays(const <int>[6, 2, 6]);
    final reloaded = await store.load();

    expect(savedDays, <int>[2, 6]);
    expect(reloaded.pace, MemorizationPlanPace.balanced24Months);
    expect(reloaded.startedAt, DateTime(2026, 9, 1));
    expect(reloaded.missedPlanDays, <int>[2, 6]);
  });

  test('saveMissedPlanDays without a plan drops orphan persisted days', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_missed_days_v1': <String>['1', '3'],
    });

    final savedDays = await const MemorizationPlanStore()
        .saveMissedPlanDays(const <int>[2, 4]);

    expect(savedDays, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('memorization_plan_missed_days_v1'), isFalse);
  });

  test('saveMissedPlanDays rejects negative days without replacing existing days', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.balanced24Months,
      startedAt: DateTime(2026, 9, 1),
      missedPlanDays: const <int>[3],
    );

    expect(
      () => store.saveMissedPlanDays(const <int>[4, -1]),
      throwsArgumentError,
    );

    final reloaded = await store.load();
    expect(reloaded.missedPlanDays, <int>[3]);
  });

  test('load drops orphan missed days when plan state is incomplete', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['1', '3'],
    });

    final snapshot = await const MemorizationPlanStore().load();

    expect(snapshot.hasPlan, isFalse);
    expect(snapshot.missedPlanDays, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('memorization_plan_missed_days_v1'), isFalse);
  });

  test('load normalizes persisted missed-day values and removes invalid entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_pace_v1': MemorizationPlanPace.steady18Months.name,
      'memorization_plan_started_at_v1': '2026-09-01T18:45:00.000',
      'memorization_plan_missed_days_v1': <String>['5', '-1', '2', 'oops', '5'],
    });

    final snapshot = await const MemorizationPlanStore().load();

    expect(snapshot.hasPlan, isTrue);
    expect(snapshot.startedAt, DateTime(2026, 9, 1));
    expect(snapshot.missedPlanDays, <int>[2, 5]);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('memorization_plan_missed_days_v1'),
      <String>['2', '5'],
    );
  });

  test('load clears the whole snapshot when persisted pace is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_pace_v1': 'retiredLegacyPace',
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['2'],
    });

    final snapshot = await const MemorizationPlanStore().load();

    expect(snapshot.hasPlan, isFalse);
    expect(snapshot.missedPlanDays, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('memorization_plan_pace_v1'), isFalse);
    expect(prefs.containsKey('memorization_plan_started_at_v1'), isFalse);
    expect(prefs.containsKey('memorization_plan_missed_days_v1'), isFalse);
  });

  test('save rejects negative missed plan days without replacing existing plan', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.balanced24Months,
      startedAt: DateTime(2026, 9, 1),
      missedPlanDays: const <int>[3],
    );

    expect(
      () => store.save(
        pace: MemorizationPlanPace.steady18Months,
        startedAt: DateTime(2026, 9, 15),
        missedPlanDays: const <int>[4, -1],
      ),
      throwsArgumentError,
    );

    final reloaded = await store.load();
    expect(reloaded.pace, MemorizationPlanPace.balanced24Months);
    expect(reloaded.startedAt, DateTime(2026, 9, 1));
    expect(reloaded.missedPlanDays, <int>[3]);
  });
}
