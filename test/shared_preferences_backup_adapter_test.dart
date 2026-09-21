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
      'prayer_notification_profile': 'discreet',
      'prayer_hijri_offset': 1,
      'reader_experience_preset_v1': 'essential',
      'reader_auto_scroll_speed_v1': 'slow',
      'offline_audio_pack_intents_v1': <String>[
        '{"storageKey":"reciter_128","surah":2,"verseCount":286}',
      ],
      'reading_plan_state_v1': '{"active":{"preset":"quran30"}}',
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
    expect(snapshot['prayer_notification_profile'], 'discreet');
    expect(snapshot['reader_experience_preset_v1'], 'essential');
    expect(snapshot['reader_auto_scroll_speed_v1'], 'slow');
    expect(snapshot['offline_audio_pack_intents_v1'], hasLength(1));
    expect(snapshot['reading_plan_state_v1'], isNotNull);
    expect(snapshot, isNot(contains('prayer_city_id')));
    for (final key in SharedPreferencesBackupAdapter.excludedPrayerLocationKeys) {
      expect(snapshot, isNot(contains(key)), reason: '$key must remain device-local');
    }
    expect(snapshot, isNot(contains('audio_cache_internal')));
  });

  test('captureSections groups new and existing data separately', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'alhamdulillah',
      'dhikr_v2_counts': '{"alhamdulillah":10}',
      'prayer_method_override': 'turkiye',
      'prayer_adjustment_fajr': 2,
      'reading_plan_state_v1': '{"active":{"preset":"quran90"}}',
      'prayer_device_latitude': 10.0,
    });

    final sections = await adapter.captureSections();

    expect((sections['dhikr'] as Map)['dhikr_v2_selected'], 'alhamdulillah');
    expect((sections['prayerPreferences'] as Map)['prayer_adjustment_fajr'], 2);
    expect((sections['readingPlans'] as Map)['reading_plan_state_v1'], isNotNull);
    expect(
      (sections['prayerPreferences'] as Map),
      isNot(contains('prayer_device_latitude')),
    );
  });

  test('version four restore replaces reading plans and safe preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'subhanallah',
      'dhikr_v2_counts': '{"subhanallah":1}',
      'prayer_asr_method': 'standard',
      'reading_plan_state_v1': '{"old":true}',
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
      'readingPlans': <String, Object?>{
        'reading_plan_state_v1': '{"active":{"preset":"quran365"}}',
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dhikr_v2_selected'), 'alhamdulillah');
    expect(prefs.getString('dhikr_v2_counts'), '{"alhamdulillah":33}');
    expect(prefs.getString('prayer_asr_method'), 'hanafi');
    expect(prefs.getInt('prayer_hijri_offset'), 1);
    expect(
      prefs.getString('reading_plan_state_v1'),
      '{"active":{"preset":"quran365"}}',
    );
    expect(prefs.getDouble('prayer_device_latitude'), 41.0);
    expect(prefs.getDouble('prayer_device_longitude'), 29.0);
  });

  test('version three restore preserves version four-only reading plan data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'dhikr_v2_counts': '{"subhanallah":99}',
      'prayer_asr_method': 'hanafi',
      'reading_plan_state_v1': '{"active":{"preset":"quran30"}}',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'reading': <String, Object?>{'last_surah': 12},
        'dhikr': <String, Object?>{'dhikr_v2_counts': '{"subhanallah":33}'},
      },
      schemaVersion: 3,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 12);
    expect(prefs.getString('dhikr_v2_counts'), '{"subhanallah":33}');
    expect(prefs.getString('reading_plan_state_v1'), '{"active":{"preset":"quran30"}}');
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
      'reading_plan_state_v1': '{"active":{"preset":"quran30"}}',
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
    expect(prefs.getString('reading_plan_state_v1'), isNotNull);
  });

  test('Essential Reader preset survives a current backup round trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
    });

    final sections = await adapter.captureSections();
    expect(
      (sections['preferences'] as Map)['reader_experience_preset_v1'],
      'essential',
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader_experience_preset_v1'), 'essential');
  });

  test('Reader auto-scroll speed survives a current backup round trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_auto_scroll_speed_v1': 'fast',
    });

    final sections = await adapter.captureSections();
    expect(
      (sections['preferences'] as Map)['reader_auto_scroll_speed_v1'],
      'fast',
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader_auto_scroll_speed_v1'), 'fast');
  });

  test('offline pack intent survives backup without audio payload', () async {
    const intent =
        '{"storageKey":"reciter_128","surah":2,"verseCount":286}';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'offline_audio_pack_intents_v1': <String>[intent],
      'audio_cache_internal': 'large-media-bytes',
    });

    final sections = await adapter.captureSections();
    expect(
      (sections['preferences'] as Map)['offline_audio_pack_intents_v1'],
      <String>[intent],
    );
    expect(sections.toString(), isNot(contains('large-media-bytes')));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('offline_audio_pack_intents_v1'),
      <String>[intent],
    );
  });

  test('version seven restore preserves newer offline pack intent', () async {
    const intent =
        '{"storageKey":"reciter_128","surah":2,"verseCount":286}';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'offline_audio_pack_intents_v1': <String>[intent],
    });

    await adapter.restoreSections(
      <String, Object?>{'preferences': <String, Object?>{}},
      schemaVersion: 7,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('offline_audio_pack_intents_v1'),
      <String>[intent],
    );
  });

  test('version six restore preserves the newer auto-scroll speed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_auto_scroll_speed_v1': 'slow',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'preferences': <String, Object?>{},
      },
      schemaVersion: 6,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader_auto_scroll_speed_v1'), 'slow');
  });

  test('version five restore preserves the new Reader preset', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
    });

    await adapter.restoreSections(
      <String, Object?>{
        'preferences': <String, Object?>{},
      },
      schemaVersion: 5,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader_experience_preset_v1'), 'essential');
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

  test('Reader history survives a sectioned backup round trip', () async {
    const history =
        '[{"surah":2,"ayah":255,"visitedAt":"2026-09-16T18:00:00.000Z"}]';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'reader_history_v1': history,
    });

    final sections = await adapter.captureSections();
    expect((sections['reading'] as Map)['reader_history_v1'], history);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 1,
      'last_ayah': 1,
      'reader_history_v1': '[]',
    });
    await adapter.restoreSections(sections);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
    expect(prefs.getString('reader_history_v1'), history);
  });

  test('memorization practice history survives a sectioned backup round trip', () async {
    const history =
        '[{"id":"practice-1","page":42,"occurredAt":"2026-09-17T01:00:00.000Z","context":"review"}]';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': history,
    });

    final sections = await adapter.captureSections();
    expect(
      (sections['memorizationPractice'] as Map)[
          'memorization_practice_history_v1'],
      history,
    );
    expect(
      (sections['memorization'] as Map),
      isNot(contains('memorization_practice_history_v1')),
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': '[]',
    });
    await adapter.restoreSections(sections);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('memorization_practice_history_v1'), history);
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
