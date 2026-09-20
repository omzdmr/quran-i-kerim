import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_recovery_destination.dart';

void main() {
  test('catch-up destination opens first canonical verse of recovery range', () {
    final active = ActiveReadingPlan(
      preset: ReadingPlanPreset.quran30,
      startedAt: DateTime(2026, 9, 1),
      completedDays: const <int>{1, 2},
    );
    final session = ReadingPlanRecoverySession.catchUp(
      active: active,
      now: DateTime(2026, 9, 5),
    );

    final destination = recoveryDestinationForSession(session);

    expect(destination, isNotNull);
    expect(destination!.mode, ReadingPlanRecoveryMode.catchUp);
    expect(destination.startPage, session.startPage);
    expect(destination.endPage, session.endPage);
    expect(destination.pageCount, session.pageCount);
    expect(destination.surah, greaterThanOrEqualTo(1));
    expect(destination.ayah, greaterThanOrEqualTo(1));
  });

  test('redistributed destination preserves exact daily page slice', () {
    final active = ActiveReadingPlan(
      preset: ReadingPlanPreset.quran30,
      startedAt: DateTime(2026, 9, 1),
      completedDays: const <int>{1, 2},
    );
    final session = ReadingPlanRecoverySession.redistributed(
      active: active,
      now: DateTime(2026, 9, 5),
      targetEndDate: DateTime(2026, 10, 5),
      forDate: DateTime(2026, 9, 5),
    );

    final destination = recoveryDestinationForSession(session)!;

    expect(destination.mode, ReadingPlanRecoveryMode.redistribute);
    expect(destination.startPage, session.startPage);
    expect(destination.endPage, session.endPage);
    expect(destination.pageCount, session.pageCount);
  });

  test('null session has no Reader destination', () {
    expect(recoveryDestinationForSession(null), isNull);
  });
}
