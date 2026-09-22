import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';

void main() {
  const planner = BackupImportPlanner();

  test('legacy restore preview ignores sections that old schema cannot touch', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2},
        'fasting': <String, Object?>{'qada_fasting_ledger_v1': 'private-new-data'},
      },
      incomingSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
      managedSections: BackupManifest.sectionsForVersion(1),
    );

    expect(plan.conflictingRecords, 1);
    expect(plan.localOnlyRecords, 0);
    expect(plan.sectionImpacts.any((impact) => impact.section == 'fasting'), isFalse);
  });

  test('missing section inside managed schema remains visible as replace removal', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2},
        'bookmarks': <String, Object?>{'bookmarks': <String>['2:255']},
      },
      incomingSections: const <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2},
      },
      managedSections: const <String>{'reading', 'bookmarks'},
    );

    final bookmarks = plan.sectionImpacts.singleWhere((impact) => impact.section == 'bookmarks');
    expect(bookmarks.localOnlyRecords, 1);
    expect(plan.localOnlyRecords, 1);
  });
}
