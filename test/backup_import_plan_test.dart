import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';

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
}
