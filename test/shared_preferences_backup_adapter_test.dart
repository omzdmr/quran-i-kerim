import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('captures reader, memorization, learning and preference data only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'reading_days': <String>['2026-09-16'],
      'reader_history_v1': '[]',
      'bookmarks': <String>['2:255'],
      'verse_notes': '{"2:255":"note"}',
      'verse_note_sources': '{"2:255":"RWD"}',
      'verse_highlights': '{"2:255":"green"}',
      'archive_times': '{"bookmark|2:255":"1"}',
      'memorized_pages_v1': <String>['1', '2'],
      'memorization_target_v1': 'juzAmma',
      'memorization_practice_history_v1': '[]',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
      'app_locale': 'tr',
      'reader_text_size': 27.0,
      'audio_cache_internal': 'never export this',
      'learn_progress_future:intro': 'unknown prefix',
      'future_unknown_preference': 'private by default',
    });

    final snapshot = await adapter.capture();

    expect(snapshot['last_surah'], 2);
    expect(snapshot['bookmarks'], <String>['2:255']);
    expect(snapshot['memorization_target_v1'], 'juzAmma');
    expect(snapshot['learn_progress_v1:intro'], isNotNull);
    expect(snapshot['app_locale'], 'tr');
    expect(snapshot, isNot(contains('audio_cache_internal')));
    expect(snapshot, isNot(contains('learn_progress_future:intro')));
    expect(snapshot, isNot(contains('future_unknown_preference')));
  });

  test('captureSections groups dynamic lesson progress under learning', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 36,
      'bookmarks': <String>['36:1'],
      'learn_progress_v1:lesson-a': '{"lessonId":"lesson-a"}',
      'learn_progress_v1:lesson-b': '{"lessonId":"lesson-b"}',
      'theme_mode': 'dark',
    });

    final sections = await adapter.captureSections();

    expect((sections['reading'] as Map)['last_surah'], 36);
    expect((sections['bookmarks'] as Map)['bookmarks'], <String>['36:1']);
    expect((sections['learning'] as Map).keys, unorderedEquals(<String>{
      'learn_progress_v1:lesson-a',
      'learn_progress_v1:lesson-b',
    }));
    expect((sections['preferences'] as Map)['theme_mode'], 'dark');
  });

  test('version two restore replaces dynamic learning progress', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'learn_progress_v1:old': '{"lessonId":"old"}',
      'unrelated': 'keep me',
    });

    await adapter.restoreSections(<String, Object?>{
      'learning': <String, Object?>{
        'learn_progress_v1:new': '{"lessonId":"new"}',
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('learn_progress_v1:old'), isFalse);
    expect(prefs.getString('learn_progress_v1:new'), '{"lessonId":"new"}');
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('version one restore preserves data introduced by version two', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'memorization_target_v1': 'juzAmma',
      'learn_progress_v1:intro': '{"lessonId":"intro"}',
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
  });

  test('restore leaves unrelated preferences alone', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'bookmarks': <String>['9:1'],
      'unrelated': 'keep me',
    });

    await adapter.restore(<String, Object?>{
      'last_surah': 2,
      'bookmarks': <Object>['2:255'],
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getStringList('bookmarks'), ['2:255']);
    expect(prefs.getString('unrelated'), 'keep me');
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
