import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  test('restoring a pre-practice-history backup preserves current Hifz history', () async {
    final history = jsonEncode([
      {
        'id': 'keep-me',
        'page': 12,
        'context': 'prayer',
        'occurredAt': '2026-09-21T10:00:00.000Z',
      },
    ]);
    SharedPreferences.setMockInitialValues({
      'memorization_practice_history_v1': history,
      'last_surah': 9,
    });

    await service.restoreDecoded({
      'version': 2,
      'createdAt': '2026-09-10T10:00:00Z',
      'data': {
        'reading': {'last_surah': 36},
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getString('memorization_practice_history_v1'), history);
  });
}
