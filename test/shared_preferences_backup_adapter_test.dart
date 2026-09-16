import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('captures reader data, memorization data and preferences only', () async {
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
      'memorization_practice_days_v1': <String>['2026-09-16'],
      'memorization_page_progress_v1': '{"1":{}}',
      'memorization_plan_pace_v1': 'balanced18Months',
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['4', '8'],
      'memorization_practice_history_v1': '[]',
      'memorization_recall_history_v1': '{}',
      'app_locale': 'tr',
      'reader_text_size': 27.0,
      'audio_cache_internal': 'never export this',
      'future_unknown_preference': 'private by default',
    });

    final snapshot = await adapter.capture();

    expect(snapshot['last_surah'], 2);
    expect(snapshot['bookmarks'], <String>['2:255']);
    expect(snapshot['memorized_pages_v1'], <String>['1', '2']);
    expect(snapshot['app_locale'], 'tr');
    expect(snapshot, isNot(contains('audio_cache_internal')));
    expect(snapshot, isNot(contains('future_unknown_preference')));
  });

  test('captureSections groups preferences under manifest section names', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 36,
      'bookmarks': <String>['36:1'],
      'verse_notes': '{"36:1":"note"}',
      'memorization_practice_history_v1': '[]',
      'theme_mode': 'dark',
    });

    final sections = await adapter.captureSections();

    expect((sections['reading'] as Map)['last_surah'], 36);
    expect((sections['bookmarks'] as Map)['bookmarks'], <String>['36:1']);
    expect((sections['notes'] as Map)['verse_notes'], isNotNull);
    expect(
      (sections['memorizationPractice'] as Map)
          ['memorization_practice_history_v1'],
      '[]',
    );
    expect((sections['preferences'] as Map)['theme_mode'], 'dark');
  });

  test('restore replaces included values and leaves unrelated preferences alone', () async {
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

  test('restoreSections clears missing included data but not unknown local data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 4,
      'bookmarks': <String>['9:4'],
      'unrelated': 'keep me',
    });

    await adapter.restoreSections(<String, Object?>{
      'reading': <String, Object?>{'last_surah': 12},
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 12);
    expect(prefs.containsKey('last_ayah'), isFalse);
    expect(prefs.containsKey('bookmarks'), isFalse);
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
