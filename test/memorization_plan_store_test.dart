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
    expect(restored.pace, MemorizationPlanPace.steady18Months);
    expect(restored.startedAt, DateTime(2026, 9, 13));
    expect(restored.hasPlan, isTrue);
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
    expect(restored.hasPlan, isFalse);
  });

  test('clearing a plan removes both persisted values', () async {
    const store = MemorizationPlanStore();
    await store.save(
      pace: MemorizationPlanPace.balanced24Months,
      startedAt: DateTime(2026, 9, 13),
    );

    await store.clear();
    final restored = await store.load();

    expect(restored.pace, isNull);
    expect(restored.startedAt, isNull);
    expect(restored.hasPlan, isFalse);
  });
}
