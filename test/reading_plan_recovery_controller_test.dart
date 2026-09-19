import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery_controller.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';

void main() {
  ActiveReadingPlan active({Set<int> completed = const <int>{}}) =>
      ActiveReadingPlan(
        preset: ReadingPlanPreset.quran30,
        startedAt: DateTime(2026, 9, 1),
        completedDays: completed,
      );

  test('persisted redistribution window drives current Reader work range', () {
    final session = resolveReadingPlanRecoverySession(
      snapshot: ReadingPlanSnapshot(
        active: active(completed: {1, 2, 3}),
        redistributionTargetEndDate: DateTime(2026, 10, 10),
      ),
      now: DateTime(2026, 9, 20),
    );

    expect(session, isNotNull);
    expect(session!.mode, ReadingPlanRecoveryMode.redistribute);
    expect(session.startPage, greaterThan(0));
    expect(session.endPage, greaterThanOrEqualTo(session.startPage));
  });

  test('missing redistribution preference uses catch-up range', () {
    final session = resolveReadingPlanRecoverySession(
      snapshot: ReadingPlanSnapshot(active: active(completed: {1, 2, 3})),
      now: DateTime(2026, 9, 20),
    );

    expect(session, isNotNull);
    expect(session!.mode, ReadingPlanRecoveryMode.catchUp);
    expect(session.catchUpTarget, isNotNull);
  });

  test('stale redistribution preference safely falls back to catch-up', () {
    final session = resolveReadingPlanRecoverySession(
      snapshot: ReadingPlanSnapshot(
        active: active(completed: {1, 2, 3}),
        redistributionTargetEndDate: DateTime(2026, 9, 10),
      ),
      now: DateTime(2026, 9, 20),
    );

    expect(session, isNotNull);
    expect(session!.mode, ReadingPlanRecoveryMode.catchUp);
  });

  test('no active plan has no recovery session', () {
    expect(
      resolveReadingPlanRecoverySession(
        snapshot: const ReadingPlanSnapshot(),
        now: DateTime(2026, 9, 20),
      ),
      isNull,
    );
  });
}
