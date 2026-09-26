import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  Future<Map<String, dynamic>> mergeProgress({
    required Map<String, Object?> local,
    required Map<String, Object?> incoming,
  }) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1'],
      'memorization_page_progress_v1': jsonEncode({'1': local}),
    });
    await service.restoreDecoded(
      {
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': {
          'memorization': {
            'memorized_pages_v1': <String>['1'],
            'memorization_page_progress_v1': jsonEncode({'1': incoming}),
          },
        },
      },
      mode: BackupRestoreMode.merge,
    );
    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(prefs.getString('memorization_page_progress_v1')!) as Map;
    return Map<String, dynamic>.from(decoded['1'] as Map);
  }

  test('newer local review is not rolled back by an older backup', () async {
    final result = await mergeProgress(
      local: {
        'memorizedAt': '2026-08-01T00:00:00.000Z',
        'lastReviewedAt': '2026-09-21T10:00:00.000Z',
        'selfAssessment': 'independent',
      },
      incoming: {
        'memorizedAt': '2026-08-01T00:00:00.000Z',
        'lastReviewedAt': '2026-09-10T10:00:00.000Z',
        'selfAssessment': 'struggled',
      },
    );

    expect(result['lastReviewedAt'], '2026-09-21T10:00:00.000Z');
    expect(result['selfAssessment'], 'independent');
  });

  test('newer incoming review advances local progress', () async {
    final result = await mergeProgress(
      local: {
        'memorizedAt': '2026-08-01T00:00:00.000Z',
        'lastReviewedAt': '2026-09-10T10:00:00.000Z',
      },
      incoming: {
        'memorizedAt': '2026-08-01T00:00:00.000Z',
        'lastReviewedAt': '2026-09-21T10:00:00.000Z',
        'selfAssessment': 'assisted',
      },
    );

    expect(result['lastReviewedAt'], '2026-09-21T10:00:00.000Z');
    expect(result['selfAssessment'], 'assisted');
  });
}
