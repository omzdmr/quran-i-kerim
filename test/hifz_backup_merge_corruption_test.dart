import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  Future<void> merge(Map<String, Object?> data) => service.restoreDecoded(
        {
          'version': BackupManifest.schemaVersion,
          'createdAt': '2026-09-21T14:00:00Z',
          'data': data,
        },
        mode: BackupRestoreMode.merge,
      );

  test('malformed local Hifz history yields to valid incoming history', () async {
    SharedPreferences.setMockInitialValues({'memorization_practice_history_v1': '{broken-json'});
    const incoming =
        '[{"id":"valid","page":1,"context":"soloReview","occurredAt":"2026-09-21T10:00:00.000Z"}]';
    await merge({'memorizationPractice': {'memorization_practice_history_v1': incoming}});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memorization_practice_history_v1'), incoming);
  });

  test('malformed incoming Hifz progress cannot overwrite valid local progress', () async {
    const local = '{"1":{"lastReviewedAt":"2026-09-21T10:00:00.000Z"}}';
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1'],
      'memorization_page_progress_v1': local,
    });
    await merge({
      'memorization': {
        'memorized_pages_v1': <String>['1'],
        'memorization_page_progress_v1': '{broken-json',
      },
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memorization_page_progress_v1'), local);
  });

  test('wrong-type incoming Hifz page list cannot replace a valid local list', () async {
    SharedPreferences.setMockInitialValues({'memorized_pages_v1': <String>['1', '2']});
    await merge({'memorization': {'memorized_pages_v1': 'not-a-list'}});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('memorized_pages_v1'), ['1', '2']);
  });

  test('malformed duplicate event cannot erase a valid local event', () async {
    final local = jsonEncode([
      {
        'id': 'same',
        'page': 7,
        'context': 'prayer',
        'occurredAt': '2026-09-21T10:00:00.000Z',
      },
    ]);
    final incoming = jsonEncode([
      {
        'id': 'same',
        'page': 7,
        'context': 'madeUpContext',
        'occurredAt': '2026-09-22T10:00:00.000Z',
      },
    ]);
    SharedPreferences.setMockInitialValues({'memorization_practice_history_v1': local});
    await merge({'memorizationPractice': {'memorization_practice_history_v1': incoming}});

    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('memorization_practice_history_v1')!) as List;
    expect(events.length, 1);
    expect((events.single as Map)['context'], 'prayer');
  });
}
