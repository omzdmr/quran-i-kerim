import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  test('merge preserves local and incoming Hifz pages, progress and history', () async {
    final localHistory = jsonEncode([
      {
        'id': 'local:1',
        'page': 1,
        'context': 'soloReview',
        'occurredAt': '2026-09-20T10:00:00.000Z',
      },
    ]);
    final incomingHistory = jsonEncode([
      {
        'id': 'incoming:2',
        'page': 2,
        'context': 'prayer',
        'occurredAt': '2026-09-21T10:00:00.000Z',
      },
    ]);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['1'],
      'memorization_practice_days_v1': <String>['2026-09-20'],
      'memorization_page_progress_v1': jsonEncode({
        '1': {'memorizedAt': '2026-09-01T10:00:00.000Z'},
      }),
      'memorization_practice_history_v1': localHistory,
    });

    await service.restoreDecoded(
      <String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': <String, Object?>{
          'memorization': <String, Object?>{
            'memorized_pages_v1': <String>['2'],
            'memorization_practice_days_v1': <String>['2026-09-21'],
            'memorization_page_progress_v1': jsonEncode({
              '2': {'memorizedAt': '2026-09-02T10:00:00.000Z'},
            }),
          },
          'memorizationPractice': <String, Object?>{
            'memorization_practice_history_v1': incomingHistory,
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('memorized_pages_v1'), ['1', '2']);
    expect(
      prefs.getStringList('memorization_practice_days_v1'),
      ['2026-09-20', '2026-09-21'],
    );

    final progress = jsonDecode(prefs.getString('memorization_page_progress_v1')!) as Map;
    expect(progress.keys.toSet(), {'1', '2'});

    final history = jsonDecode(prefs.getString('memorization_practice_history_v1')!) as List;
    expect(history.length, 2);
    expect((history.first as Map)['id'], 'incoming:2');
    expect(history.map((event) => (event as Map)['id']).toSet(), {
      'local:1',
      'incoming:2',
    });
  });

  test('incoming event with same id wins without duplicating history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': jsonEncode([
        {
          'id': 'same',
          'page': 1,
          'context': 'soloReview',
          'occurredAt': '2026-09-20T10:00:00.000Z',
        },
      ]),
    });

    await service.restoreDecoded(
      <String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': <String, Object?>{
          'memorizationPractice': <String, Object?>{
            'memorization_practice_history_v1': jsonEncode([
              {
                'id': 'same',
                'page': 1,
                'context': 'prayer',
                'occurredAt': '2026-09-21T10:00:00.000Z',
              },
            ]),
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    final history = jsonDecode(prefs.getString('memorization_practice_history_v1')!) as List;
    expect(history.length, 1);
    expect((history.single as Map)['context'], 'prayer');
  });
}
