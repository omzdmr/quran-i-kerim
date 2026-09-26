import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';

void main() {
  const parser = BackupPreviewParser();

  test('portable restore rejects every exact prayer-location preference', () {
    for (final privateKey in SharedPreferencesBackupAdapter.excludedPrayerLocationKeys) {
      final preview = parser.parse(<String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{
          'prayerPreferences': <String, Object?>{privateKey: 'private-location-value'},
        },
      });
      expect(preview.canRestore, isFalse, reason: privateKey);
      expect(preview.issues, contains(BackupPreviewIssue.unsupportedData), reason: privateKey);
    }
  });

  test('portable restore still accepts non-location prayer behavior', () {
    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'prayerPreferences': <String, Object?>{
          'prayer_asr_method': 'hanafi',
          'prayer_hijri_offset': 1,
        },
      },
    });
    expect(preview.canRestore, isTrue);
  });
}
