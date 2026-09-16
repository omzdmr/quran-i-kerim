import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('exports current schema with explicit sections only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'bookmarks': <String>['2:255'],
      'verse_notes': '{"2:255":"note"}',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'theme_mode': 'dark',
      'audio_cache_internal': 'do not export',
    });

    final encoded = await service.exportJson(
      now: DateTime.parse('2026-09-16T18:00:00+08:00'),
    );
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    expect(decoded['version'], 2);
    expect(decoded['createdAt'], '2026-09-16T10:00:00.000Z');
    expect((data['reading'] as Map)['last_surah'], 2);
    expect((data['bookmarks'] as Map)['bookmarks'], ['2:255']);
    expect((data['learning'] as Map)['learn_progress_v1:intro'], isNotNull);
    expect((data['preferences'] as Map)['theme_mode'], 'dark');
    expect(encoded, isNot(contains('audio_cache_internal')));
  });

  test('restores current backup and keeps unrelated local preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'learn_progress_v1:old': '{"lessonId":"old"}',
      'unrelated': 'keep me',
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
        'learning': <String, Object?>{
          'learn_progress_v1:new': '{"lessonId":"new"}',
        },
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(prefs.containsKey('learn_progress_v1:old'), isFalse);
    expect(prefs.getString('learn_progress_v1:new'), isNotNull);
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('version one restore preserves version two-only local data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'memorization_target_v1': 'juzAmma',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 1,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
        'memorization': <String, Object?>{},
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getString('memorization_target_v1'), 'juzAmma');
    expect(prefs.getString('learn_progress_v1:intro'), isNotNull);
  });

  test('rolls back if a current backup fails while applying', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 4,
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'unrelated': 'keep me',
    });

    await expectLater(
      service.restoreDecoded(<String, Object?>{
        'version': 2,
        'createdAt': '2026-09-16T10:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{
            'last_surah': 12,
            'last_ayah': <Object>[42],
          },
          'learning': <String, Object?>{},
        },
      }),
      throwsFormatException,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
    expect(prefs.getInt('last_ayah'), 4);
    expect(prefs.getString('learn_progress_v1:intro'), isNotNull);
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('rejects unsupported version before mutating local data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9});

    await expectLater(
      service.restoreDecoded(<String, Object?>{
        'version': 99,
        'createdAt': '2026-09-16T10:00:00Z',
        'data': <String, Object?>{},
      }),
      throwsFormatException,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
  });
}
