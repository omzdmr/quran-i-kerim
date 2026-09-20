import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';

void main() {
  test('current schema includes user-created progress and safe preferences', () {
    expect(BackupManifest.schemaVersion, 5);
    expect(BackupManifest.includedSections, containsAll(<String>{
      'reading',
      'bookmarks',
      'highlights',
      'notes',
      'memorization',
      'memorizationPractice',
      'preferences',
      'learning',
      'dhikr',
      'prayerPreferences',
      'readingPlans',
    }));
  });

  test('explicitly excludes large, re-downloadable and location content', () {
    expect(BackupManifest.excludedSections, containsAll(<String>{
      'quranText',
      'translations',
      'audioCache',
      'memorizationRecordings',
      'prayerLocation',
    }));
  });

  test('older restore scopes do not include sections introduced later', () {
    expect(BackupManifest.isVersionSupported(1), isTrue);
    expect(BackupManifest.isVersionSupported(2), isTrue);
    expect(BackupManifest.isVersionSupported(3), isTrue);
    expect(BackupManifest.isVersionSupported(4), isTrue);
    expect(BackupManifest.isVersionSupported(5), isTrue);
    expect(BackupManifest.sectionsForVersion(1), isNot(contains('learning')));
    expect(BackupManifest.sectionsForVersion(2), contains('learning'));
    expect(BackupManifest.sectionsForVersion(2), isNot(contains('dhikr')));
    expect(BackupManifest.sectionsForVersion(2), isNot(contains('prayerPreferences')));
    expect(BackupManifest.sectionsForVersion(3), contains('dhikr'));
    expect(BackupManifest.sectionsForVersion(3), contains('prayerPreferences'));
    expect(BackupManifest.sectionsForVersion(3), isNot(contains('readingPlans')));
    expect(BackupManifest.sectionsForVersion(4), contains('readingPlans'));
    expect(BackupManifest.sectionsForVersion(5), contains('readingPlans'));
  });

  test('unknown and excluded sections never leak into selected data', () {
    final selected = BackupManifest.selectBackupData(<String, Object?>{
      'notes': <Object>[1],
      'dhikr': <String, Object?>{'dhikr_v2_selected': 'subhanallah'},
      'prayerPreferences': <String, Object?>{'prayer_hijri_offset': 1},
      'readingPlans': <String, Object?>{'reading_plan_state_v1': '{}'},
      'prayerLocation': <String, Object?>{'latitude': 1.0},
      'audioCache': <Object>[2],
      'futureUnknown': <Object>[3],
    });

    expect(
      selected.keys,
      unorderedEquals(<String>[
        'notes',
        'dhikr',
        'prayerPreferences',
        'readingPlans',
      ]),
    );
  });

  test('included and excluded sections never overlap', () {
    expect(
      BackupManifest.includedSections.intersection(BackupManifest.excludedSections),
      isEmpty,
    );
  });
}
