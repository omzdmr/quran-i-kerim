import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('captures user data while excluding exact prayer location', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'bookmarks': <String>['2:255'],
      'memorization_target_v1': 'juzAmma',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'dhikr_v2_selected': 'subhanallah',
      'dhikr_v2_counts': '{"subhanallah":33}',
      'dhikr_v2_custom': '[{"id":"custom:1","label":"My dhikr"}]',
      'prayer_asr_method': 'hanafi',
      'prayer_notifications_enabled': true,
      'prayer_notification_ids': <String>['fajr', 'isha'],
      'prayer_hijri_offset': 1,
      'prayer_city_id': '__device_location__',
      'prayer_device_latitude': 41.123456,
      'prayer_device_longitude': 29.123456,
      'prayer_device_timezone': 'Europe/Istanbul',
      'prayer_manual_latitude': 39.0,
      'prayer_manual_longitude': 35.0,
      'audio_cache_internal': 'never export this',
    });

    final snapshot = await adapter.capture();

    expect(snapshot['last_surah'], 2);
    expect(snapshot['memorization_target_v1'], 'juzAmma');
    expect(snapshot['learn_progress_v1:intro'], isNotNull);
    expect(snapshot['dhikr_v2_selected'], 'subhanallah');
    expect(snapshot['prayer_asr_method'], 'hanafi');
    expect(snapshot['prayer_notification_ids'], <String>['fajr', 'isha']);
    expect(snapshot, isNot(contains('prayer_city_id')));
    for (final key in SharedPreferencesBackupAdapter.excludedPrayerLocationKeys) {
      expect(snapshot, isNot(contains(key)), reason: '$key must remain device-local');
    }
    expect(snapshot, isNot(contains('audio_cache_internal')));
  });

  test('captureSections groups dhikr and safe prayer preferences separately', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'alhamdulillah',
      'dhikr_v2_counts': '{"alhamdulillah":10}',
      'prayer_method_override': 'turkiye',
      'prayer_adjustment_fajr': 2,
      'prayer_device_latitude': 10.0,
    });

    final sections = await adapter.captureSections();

    expect((sections['dhikr'] as Map)['dhikr_v2_selected'], 'alhamdulillah');
    expect((sections['prayerPreferences'] as Map)['prayer_adjustment_fajr'], 2);
    expect(
      (sections['prayerPreferences'] as Map),
      isNot(contains('prayer_device_latitude')),
    );
  });

  test('version three restore replaces dhikr and safe prayer preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'subhanallah',
      'dhikr_v2_counts': '{"subhanallah":1}',
      'prayer_asr_method': 'standard',
      'prayer_device_latitude': 41.0,
      'prayer_device_longitude': 29.0,
    });

    await adapter.restoreSections(<String, Object?>{
      'dhikr': <String, Object?>{
        'dhikr_v2_selected': 'alhamdulillah',
        'dhikr_v2_counts': '{"alhamdulillah":33}',
      },
      'prayerPreferences': <String, Object?>{
        'prayer_asr_method': 'hanafi',
        'prayer_hijri_offset': 1,
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dhikr_v2_selected'), 'alhamdulillah');
    expect(prefs.getString('dhikr_v2_counts'), '{"alhamdulillah":33}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
    expect(prefs.getInt('prayer_hijri_offset'), 1);
    expect(prefs.getDouble('prayer_device_latitude'), 41.0);
    expect(prefs.getDouble('prayer_device_longitude'), 29.0);
  });

  test('version two restore preserves version three-only user data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'dhikr_v2_counts': '{"subhanallah":99}',
      'prayer_asr_method': 'hanafi',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'reading': <String, Object?>{'last_surah': 12},
      },
      schemaVersion: 2,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 12);
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":99}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
  });

  test('version one restore preserves data introduced by later schemas', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'memorization_target_v1': 'juzAmma',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'dhikr_v2_counts': '{"subhanallah":99}',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'reading': <String, Object?>{'last_surah': 12},
        'memorization': <String, Object?>{},
      },
      schemaVersion: 1,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 12);
    expect(prefs.getString('memorization_target_v1'), 'juzAmma');
    expect(prefs.getString('learn_progress_v1:intro'), isNotNull);
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":99}');
  });

  test('version two dynamic learning restore still works', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'learn_progress_v1:old': '{"lessonId":"old"}',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'learning': <String, Object?>{
          'learn_progress_v1:new': '{"lessonId":"new"}',
        },
      },
      schemaVersion: 2,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('learn_progress_v1:old'), isFalse);
    expect(prefs.getString('learn_progress_v1:new'), '{"lessonId":"new"}');
  });

  test('unsupported values fail instead of being silently coerced', () async {
    await expectLater(
      adapter.restore(<String, Object?>{
        'bookmarks': <Object>[1, 2],
      }),
      throwsFormatException,
    );
  });
}
