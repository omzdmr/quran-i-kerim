import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery_coordinator.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ReadingPlanStore();
  const coordinator = ReadingPlanRecoveryCoordinator();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('current destination follows persisted redistribution strategy', () async {
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 17));
    final selected = await coordinator.redistributeUntil(
      DateTime(2026, 10, 19),
      now: now,
    );

    final restored = await const ReadingPlanRecoveryCoordinator()
        .currentDestination(now: now);

    expect(selected, isNotNull);
    expect(restored, isNotNull);
    expect(restored!.mode, ReadingPlanRecoveryMode.redistribute);
    expect(restored.startPage, selected!.startPage);
    expect(restored.endPage, selected.endPage);
    expect(restored.surah, selected.surah);
    expect(restored.ayah, selected.ayah);
  });

  test('switching to catch-up changes destination without completing days', () async {
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 17));
    await coordinator.redistributeUntil(DateTime(2026, 10, 19), now: now);

    final destination = await coordinator.useCatchUp(now: now);
    final snapshot = await store.load();

    expect(destination, isNotNull);
    expect(destination!.mode, ReadingPlanRecoveryMode.catchUp);
    expect(snapshot.redistributionTargetEndDate, isNull);
    expect(snapshot.active!.completedDays, isEmpty);
  });

  test('no active plan has no recovery destination', () async {
    expect(
      await coordinator.currentDestination(now: DateTime(2026, 9, 20)),
      isNull,
    );
  });
}
