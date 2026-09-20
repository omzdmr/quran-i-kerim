import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery_service.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ReadingPlanStore();
  const service = ReadingPlanRecoveryService(store: store);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('redistribution choice persists and restores the same recovery mode', () async {
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 17));

    final selected = await service.redistributeUntil(
      DateTime(2026, 10, 19),
      now: now,
    );
    expect(selected, isNotNull);
    expect(selected!.mode, ReadingPlanRecoveryMode.redistribute);

    final restored = await const ReadingPlanRecoveryService().currentSession(now: now);
    expect(restored, isNotNull);
    expect(restored!.mode, ReadingPlanRecoveryMode.redistribute);
    expect(restored.startPage, selected.startPage);
    expect(restored.endPage, selected.endPage);
  });

  test('switching back to catch-up clears redistribution without completing work', () async {
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 17));
    await service.redistributeUntil(DateTime(2026, 10, 19), now: now);

    final before = await store.load();
    expect(before.redistributionTargetEndDate, isNotNull);
    expect(before.active!.completedDays, isEmpty);

    final catchUp = await service.useCatchUp(now: now);
    final after = await store.load();
    expect(catchUp, isNotNull);
    expect(catchUp!.mode, ReadingPlanRecoveryMode.catchUp);
    expect(after.redistributionTargetEndDate, isNull);
    expect(after.active!.completedDays, isEmpty);
  });

  test('past redistribution target is rejected and existing strategy is preserved', () async {
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: DateTime(2026, 9, 17));
    await service.redistributeUntil(DateTime(2026, 10, 19), now: now);

    await expectLater(
      service.redistributeUntil(DateTime(2026, 9, 19), now: now),
      throwsArgumentError,
    );

    final snapshot = await store.load();
    expect(snapshot.redistributionTargetEndDate, DateTime(2026, 10, 19));
    expect(snapshot.active!.completedDays, isEmpty);
  });

  test('no active plan resolves to no recovery session', () async {
    final session = await service.currentSession(now: DateTime(2026, 9, 20));
    expect(session, isNull);
  });
}
