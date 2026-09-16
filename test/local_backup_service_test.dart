import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('exports current schema with safe user-owned sections only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'dhikr_v2_selected': 'subhanallah',
      'prayer_hijri_offset': 1,
      'prayer_device_latitude': 41.0,
      'prayer_device_longitude': 29.0,
      'audio_cache_internal': 'do not export',
    });

    final encoded = await service.exportJson(
      now: DateTime.parse('2026-09-16T18:00:00+08:00'),
    );
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    expect(decoded['version'], 3);
    expect(decoded['createdAt'], '2026-09-16T10:00:00.000Z');
    expect((data['reading'] as Map)['last_surah'], 2);
    expect((data['learning'] as Map)['learn_progress_v1:intro'], isNotNull);
    expect((data['dhikr'] as Map)['dhikr_v2_selected'], 'subhanallah');
    expect((data['prayerPreferences'] as Map)['prayer_hijri_offset'], 1);
    expect(encoded, isNot(contains('prayer_device_latitude')));
    expect(encoded, isNot(contains('prayer_device_longitude')));
    expect(encoded, isNot(contains('audio_cache_internal')));
  });

  test('restores current dhikr and prayer preferences without location data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_counts': '{"subhanallah":1}',
      'prayer_asr_method': 'standard',
      'prayer_device_latitude': 41.0,
      'prayer_device_longitude': 29.0,
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'dhikr': <String, Object?>{
          'dhikr_v2_counts': '{"subhanallah":33}',
        },
        'prayerPreferences': <String, Object?>{
          'prayer_asr_method': 'hanafi',
        },
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":33}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
    expect(prefs.getDouble('prayer_device_latitude'), 41.0);
    expect(prefs.getDouble('prayer_device_longitude'), 29.0);
  });

  test('version two restore preserves version three-only local data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'dhikr_v2_counts': '{"subhanallah":99}',
      'prayer_asr_method': 'hanafi',
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":99}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
  });

  test('rolls back current data if apply fails', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'dhikr_v2_counts': '{"subhanallah":99}',
      'prayer_asr_method': 'hanafi',
      'unrelated': 'keep me',
    });

    await expectLater(
      service.restoreDecoded(<String, Object?>{
        'version': 3,
        'createdAt': '2026-09-16T10:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{
            'last_surah': <Object>[42],
          },
          'dhikr': <String, Object?>{},
          'prayerPreferences': <String, Object?>{},
        },
      }),
      throwsFormatException,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":99}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
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
