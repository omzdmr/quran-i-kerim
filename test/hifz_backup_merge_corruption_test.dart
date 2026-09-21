import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  test('malformed local Hifz history yields to valid incoming history', () async {
    SharedPreferences.setMockInitialValues({
      'memorization_practice_history_v1': '{broken-json',
    });
    const incoming =
        '[{"id":"valid","page":1,"context":"soloReview","occurredAt":"2026-09-21T10:00:00.000Z"}]';

    await service.restoreDecoded(
      {
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': {
          'memorizationPractice': {
            'memorization_practice_history_v1': incoming,
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memorization_practice_history_v1'), incoming);
  });

  test('malformed incoming Hifz progress cannot overwrite valid local progress', () async {
    const local =
        '{"1":{"lastReviewedAt":"2026-09-21T10:00:00.000Z"}}';
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1'],
      'memorization_page_progress_v1': local,
    });

    await service.restoreDecoded(
      {
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': {
          'memorization': {
            'memorized_pages_v1': <String>['1'],
            'memorization_page_progress_v1': '{broken-json',
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memorization_page_progress_v1'), local);
  });

  test('wrong-type incoming Hifz page list cannot replace a valid local list', () async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1', '2'],
    });

    await service.restoreDecoded(
      {
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': {
          'memorization': {
            'memorized_pages_v1': 'not-a-list',
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('memorized_pages_v1'), ['1', '2']);
  });
}
