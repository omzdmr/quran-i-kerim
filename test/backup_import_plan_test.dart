import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  const planner = BackupImportPlanner();

  test('counts conflicts and one-sided records before import', () {
    final plan = planner.build(currentSections: const <String, Object?>{'reading': <String, Object?>{'last_surah': 2, 'last_ayah': 255}, 'preferences': <String, Object?>{'theme_mode': 'dark'}}, incomingSections: const <String, Object?>{'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 255}, 'preferences': <String, Object?>{'app_locale': 'tr'}});
    expect(plan.localRecords, 3); expect(plan.incomingRecords, 3); expect(plan.conflictingRecords, 1); expect(plan.incomingOnlyRecords, 1); expect(plan.localOnlyRecords, 1); expect(plan.hasConflicts, isTrue);
  });

  test('deep-equal nested values are not reported as conflicts', () {
    final plan = planner.build(currentSections: const <String, Object?>{'notes': <String, Object?>{'verse_notes': <String, Object?>{'2:255': 'note'}}}, incomingSections: const <String, Object?>{'notes': <String, Object?>{'verse_notes': <String, Object?>{'2:255': 'note'}}});
    expect(plan.conflictingRecords, 0); expect(plan.hasConflicts, isFalse);
  });

  test('qada ledger is compared by immutable events rather than one blob', () {
    final local = QadaFastingLedger().addDebt(days: 3, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, id: 'shared').complete(occurredOn: DateTime(2026, 8, 1), createdAt: DateTime.utc(2026, 8, 1), sourceRamadanYear: 1446, id: 'local-only');
    final remote = QadaFastingLedger().addDebt(days: 3, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, id: 'shared').addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 2, 1), sourceRamadanYear: 1447, id: 'remote-only');
    final plan = planner.build(
      currentSections: <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: local.encode()}},
      incomingSections: <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()}},
    );
    expect(plan.localRecords, 2); expect(plan.incomingRecords, 2); expect(plan.conflictingRecords, 0); expect(plan.localOnlyRecords, 1); expect(plan.incomingOnlyRecords, 1);
  });

  test('same qada event id with changed content is a visible conflict', () {
    final local = QadaFastingLedger().addDebt(days: 3, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, id: 'same');
    final remote = QadaFastingLedger().addDebt(days: 4, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, id: 'same');
    final plan = planner.build(currentSections: <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: local.encode()}}, incomingSections: <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()}});
    expect(plan.conflictingRecords, 1); expect(plan.hasConflicts, isTrue);
  });
}
