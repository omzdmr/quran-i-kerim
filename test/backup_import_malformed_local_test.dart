import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';

void main() {
  const planner = BackupImportPlanner();

  test('malformed local qada data falls back to one visible preference conflict', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'fasting': <String, Object?>{'qada_fasting_ledger_v1': '{broken'},
      },
      incomingSections: const <String, Object?>{
        'fasting': <String, Object?>{
          'qada_fasting_ledger_v1': '{"formatVersion":1,"entries":[]}',
        },
      },
    );

    expect(plan.conflictingRecords, 1);
    expect(plan.incomingOnlyRecords, 0);
    expect(plan.localOnlyRecords, 0);
    expect(plan.changedSections.single.section, 'fasting');
  });

  test('missing qada ledger compares as an empty event set', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{'fasting': <String, Object?>{}},
      incomingSections: const <String, Object?>{
        'fasting': <String, Object?>{
          'qada_fasting_ledger_v1': '{"formatVersion":1,"entries":[{"id":"one"}]}',
        },
      },
    );

    expect(plan.incomingOnlyRecords, 1);
    expect(plan.localOnlyRecords, 0);
  });
}
