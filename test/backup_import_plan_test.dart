import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  const planner = BackupImportPlanner();

  test('counts conflicts and one-sided records before import', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2, 'last_ayah': 255},
        'preferences': <String, Object?>{'theme_mode': 'dark'},
      },
      incomingSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 255},
        'preferences': <String, Object?>{'app_locale': 'tr'},
      },
    );
    expect(plan.localRecords, 3);
    expect(plan.incomingRecords, 3);
    expect(plan.conflictingRecords, 1);
    expect(plan.incomingOnlyRecords, 1);
    expect(plan.localOnlyRecords, 1);
    expect(plan.hasConflicts, isTrue);
  });

  test('exposes deterministic section-level restore impact', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'notes': <String, Object?>{'2:255': 'local'},
        'bookmarks': <String, Object?>{'2:255': true, '18:10': true},
      },
      incomingSections: const <String, Object?>{
        'notes': <String, Object?>{'2:255': 'remote', '36:1': 'new'},
        'bookmarks': <String, Object?>{'2:255': true},
      },
    );

    expect(plan.sectionImpacts.map((impact) => impact.section), [
      'bookmarks',
      'notes',
    ]);
    final bookmarks = plan.sectionImpacts.first;
    expect(bookmarks.conflictingRecords, 0);
    expect(bookmarks.incomingOnlyRecords, 0);
    expect(bookmarks.localOnlyRecords, 1);
    final notes = plan.sectionImpacts.last;
    expect(notes.conflictingRecords, 1);
    expect(notes.incomingOnlyRecords, 1);
    expect(notes.localOnlyRecords, 0);
    expect(plan.changedSections, hasLength(2));
  });

  test('unchanged sections stay available for audit but not changedSections', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'reader': <String, Object?>{'last_surah': 2},
      },
      incomingSections: const <String, Object?>{
        'reader': <String, Object?>{'last_surah': 2},
      },
    );

    expect(plan.sectionImpacts, hasLength(1));
    expect(plan.sectionImpacts.single.hasChanges, isFalse);
    expect(plan.changedSections, isEmpty);
  });

  test('deep-equal nested values are not reported as conflicts', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'notes': <String, Object?>{
          'verse_notes': <String, Object?>{'2:255': 'note'},
        },
      },
      incomingSections: const <String, Object?>{
        'notes': <String, Object?>{
          'verse_notes': <String, Object?>{'2:255': 'note'},
        },
      },
    );
    expect(plan.conflictingRecords, 0);
    expect(plan.hasConflicts, isFalse);
  });

  test('qada ledger is compared by immutable events rather than one blob', () {
    final local = QadaFastingLedger()
        .addDebt(
          days: 3,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 1, 1),
          sourceRamadanYear: 1446,
          id: 'shared',
        )
        .complete(
          occurredOn: DateTime(2026, 8, 1),
          createdAt: DateTime.utc(2026, 8, 1),
          sourceRamadanYear: 1446,
          id: 'local-only',
        );
    final remote = QadaFastingLedger()
        .addDebt(
          days: 3,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 1, 1),
          sourceRamadanYear: 1446,
          id: 'shared',
        )
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 2, 1),
          sourceRamadanYear: 1447,
          id: 'remote-only',
        );
    final plan = planner.build(
      currentSections: <String, Object?>{
        'fasting': <String, Object?>{QadaFastingStore.preferenceKey: local.encode()},
      },
      incomingSections: <String, Object?>{
        'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()},
      },
    );
    expect(plan.localRecords, 2);
    expect(plan.incomingRecords, 2);
    expect(plan.conflictingRecords, 0);
    expect(plan.localOnlyRecords, 1);
    expect(plan.incomingOnlyRecords, 1);
    expect(plan.changedSections.single.section, 'fasting');
  });

  test('same qada event id with changed content is a visible conflict', () {
    final local = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2025, 3, 1),
      createdAt: DateTime.utc(2026, 1, 1),
      sourceRamadanYear: 1446,
      id: 'same',
    );
    final remote = QadaFastingLedger().addDebt(
      days: 4,
      occurredOn: DateTime(2025, 3, 1),
      createdAt: DateTime.utc(2026, 1, 1),
      sourceRamadanYear: 1446,
      id: 'same',
    );
    final plan = planner.build(
      currentSections: <String, Object?>{
        'fasting': <String, Object?>{QadaFastingStore.preferenceKey: local.encode()},
      },
      incomingSections: <String, Object?>{
        'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()},
      },
    );
    expect(plan.conflictingRecords, 1);
    expect(plan.hasConflicts, isTrue);
    expect(plan.changedSections.single.conflictingRecords, 1);
  });

  test('future fasting preferences remain visible beside expanded qada events', () {
    final ledger = QadaFastingLedger().addDebt(
      days: 1,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 1, 1),
      id: 'debt',
    );
    final plan = planner.build(
      currentSections: <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: ledger.encode(),
          'future_fasting_pref': 'local',
        },
      },
      incomingSections: <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: ledger.encode(),
          'future_fasting_pref': 'remote',
        },
      },
    );
    expect(plan.localRecords, 2);
    expect(plan.incomingRecords, 2);
    expect(plan.conflictingRecords, 1);
    expect(plan.hasConflicts, isTrue);
    expect(plan.changedSections.single.section, 'fasting');
  });
}
