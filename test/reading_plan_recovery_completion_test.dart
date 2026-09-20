import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('catch-up completion only advances after explicit user action', () async {
    const store = ReadingPlanStore();
    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 1, 1),
    );

    final before = await store.load();
    expect(before.active!.completedPrefixDays, 0);

    final after = await store.completeThroughDay(
      3,
      now: DateTime(2026, 1, 4),
    );

    expect(after.active, isNotNull);
    expect(after.active!.completedPrefixDays, 3);
    expect(after.active!.completedDays, containsAll(<int>{1, 2, 3}));
  });

  test('completing through final day moves plan to history', () async {
    const store = ReadingPlanStore();
    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 1, 1),
    );

    final after = await store.completeThroughDay(
      30,
      now: DateTime(2026, 1, 30),
    );

    expect(after.active, isNull);
    expect(after.completed, hasLength(1));
    expect(after.completed.single.preset, ReadingPlanPreset.quran30);
  });
}
