import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';

void main() {
  test('current schema includes user-created progress and settings', () {
    expect(BackupManifest.schemaVersion, 2);
    expect(BackupManifest.includedSections, containsAll(<String>{
      'reading',
      'bookmarks',
      'highlights',
      'notes',
      'memorization',
      'memorizationPractice',
      'preferences',
      'learning',
    }));
  });

  test('explicitly excludes large or re-downloadable content', () {
    expect(BackupManifest.excludedSections, containsAll(<String>{
      'quranText',
      'translations',
      'audioCache',
      'memorizationRecordings',
    }));
  });

  test('version one restore scope does not include later learning section', () {
    expect(BackupManifest.isVersionSupported(1), isTrue);
    expect(BackupManifest.sectionsForVersion(1), isNot(contains('learning')));
    expect(BackupManifest.sectionsForVersion(2), contains('learning'));
  });

  test('unknown and excluded sections never leak into selected data', () {
    final selected = BackupManifest.selectBackupData(<String, Object?>{
      'notes': <Object>[1],
      'learning': <String, Object?>{'learn_progress_v1:a': '{}'},
      'audioCache': <Object>[2],
      'futureUnknown': <Object>[3],
    });

    expect(selected.keys, unorderedEquals(<String>['notes', 'learning']));
  });

  test('included and excluded sections never overlap', () {
    expect(
      BackupManifest.includedSections.intersection(BackupManifest.excludedSections),
      isEmpty,
    );
  });
}
