import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = ReadingPlanStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('redistribution target survives store reload without completing days', () async {
    final started = await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 9, 1),
    );
    expect(started.active?.completedDays, isEmpty);

    final updated = await store.setRedistributionTargetEndDate(
      DateTime(2026, 10, 15, 22, 30),
      now: DateTime(2026, 9, 20),
    );
    expect(updated.redistributionTargetEndDate, DateTime(2026, 10, 15));
    expect(updated.active?.completedDays, isEmpty);

    final restored = await store.load();
    expect(restored.redistributionTargetEndDate, DateTime(2026, 10, 15));
    expect(restored.active?.completedDays, isEmpty);
  });

  test('pause and resume preserve selected redistribution window', () async {
    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 9, 1),
    );
    await store.setRedistributionTargetEndDate(
      DateTime(2026, 10, 10),
      now: DateTime(2026, 9, 20),
    );

    await store.pauseActive(now: DateTime(2026, 9, 20));
    final paused = await store.load();
    expect(paused.redistributionTargetEndDate, DateTime(2026, 10, 10));

    await store.resumeActive(now: DateTime(2026, 9, 22));
    final resumed = await store.load();
    expect(resumed.redistributionTargetEndDate, DateTime(2026, 10, 10));
  });

  test('new or stopped plan clears stale redistribution state', () async {
    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 9, 1),
    );
    await store.setRedistributionTargetEndDate(
      DateTime(2026, 10, 10),
      now: DateTime(2026, 9, 20),
    );

    final stopped = await store.stopActive();
    expect(stopped.active, isNull);
    expect(stopped.redistributionTargetEndDate, isNull);

    final restarted = await store.start(
      ReadingPlanPreset.quran90,
      now: DateTime(2026, 9, 21),
    );
    expect(restarted.redistributionTargetEndDate, isNull);
  });

  test('past redistribution target is rejected', () async {
    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 9, 1),
    );

    expect(
      () => store.setRedistributionTargetEndDate(
        DateTime(2026, 9, 19),
        now: DateTime(2026, 9, 20),
      ),
      throwsArgumentError,
    );
  });
}
