import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';

void main() {
  test('includes small user-created and progress data', () {
    expect(BackupManifest.isIncluded('notes'), isTrue);
    expect(BackupManifest.isIncluded('highlights'), isTrue);
    expect(BackupManifest.isIncluded('memorization'), isTrue);
    expect(BackupManifest.isIncluded('memorizationPractice'), isTrue);
  });

  test('explicitly excludes large or reproducible content', () {
    expect(BackupManifest.isExcluded('quranText'), isTrue);
    expect(BackupManifest.isExcluded('translations'), isTrue);
    expect(BackupManifest.isExcluded('audioCache'), isTrue);
    expect(BackupManifest.isExcluded('memorizationRecordings'), isTrue);
  });

  test('selectBackupData never leaks unknown or excluded sections', () {
    final selected = BackupManifest.selectBackupData(<String, Object?>{
      'notes': <String>['n1'],
      'memorization': <String, Object?>{'page': 12},
      'audioCache': <String>['large.mp3'],
      'futureSecret': 'must-not-be-backed-up-by-default',
    });

    expect(selected.keys, containsAll(<String>['notes', 'memorization']));
    expect(selected, isNot(contains('audioCache')));
    expect(selected, isNot(contains('futureSecret')));
  });

  test('included and excluded sections never overlap', () {
    expect(
      BackupManifest.includedSections.intersection(BackupManifest.excludedSections),
      isEmpty,
    );
  });
}
