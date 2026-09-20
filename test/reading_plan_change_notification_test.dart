import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ReadingPlanStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('plan writes notify already-mounted plan surfaces', () async {
    final before = ReadingPlanStore.changes.value;

    await store.start(
      ReadingPlanPreset.quran30,
      now: DateTime(2026, 9, 16),
    );
    expect(ReadingPlanStore.changes.value, before + 1);

    await store.completeNextDay(now: DateTime(2026, 9, 16));
    expect(ReadingPlanStore.changes.value, before + 2);
  });

  test('backup restore can broadcast an external plan-state change', () {
    final before = ReadingPlanStore.changes.value;

    ReadingPlanStore.notifyExternalChange();

    expect(ReadingPlanStore.changes.value, before + 1);
  });
}
