import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';

void main() {
  const planner = BackupImportPlanner();

  test('bookmark additions and removals are counted as user records', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'bookmarks': <String, Object?>{
          'bookmarks': <String>['2:255', '18:10', '36:1'],
        },
      },
      incomingSections: const <String, Object?>{
        'bookmarks': <String, Object?>{
          'bookmarks': <String>['2:255', '67:1'],
        },
      },
    );

    final impact = plan.sectionImpacts.single;
    expect(impact.localRecords, 3);
    expect(impact.incomingRecords, 2);
    expect(impact.conflictingRecords, 0);
    expect(impact.incomingOnlyRecords, 1);
    expect(impact.localOnlyRecords, 2);
  });

  test('identical bookmark sets do not appear as changed', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'bookmarks': <String, Object?>{
          'bookmarks': <String>['2:255', '18:10'],
        },
      },
      incomingSections: const <String, Object?>{
        'bookmarks': <String, Object?>{
          'bookmarks': <String>['2:255', '18:10'],
        },
      },
    );

    expect(plan.changedSections, isEmpty);
    expect(plan.conflictingRecords, 0);
  });

  test('invalid bookmark list falls back to preference-level comparison', () {
    final plan = planner.build(
      currentSections: const <String, Object?>{
        'bookmarks': <String, Object?>{'bookmarks': <Object>['2:255', 42]},
      },
      incomingSections: const <String, Object?>{
        'bookmarks': <String, Object?>{'bookmarks': <String>['2:255']},
      },
    );

    expect(plan.conflictingRecords, 1);
  });
}
