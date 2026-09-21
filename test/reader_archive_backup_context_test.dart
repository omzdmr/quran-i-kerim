import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> _seed() => <String, Object>{
  'bookmarks': <String>['36:1'],
  'verse_notes': jsonEncode(<String, String>{'2:255': 'private note'}),
  'verse_note_sources': jsonEncode(<String, String>{'2:255': 'RWD'}),
  'archive_times': jsonEncode(<String, String>{
    'bookmark|36:1': '100',
    'note|2:255': '200',
  }),
  'reader_history_v1': jsonEncode(<Map<String, Object>>[
    <String, Object>{
      'surah': 36,
      'ayah': 1,
      'sourceId': 'french_rashid',
      'updatedAt': 300,
    },
  ]),
};

void main() {
  test('portable backup keeps canonical archive and display-source context', () async {
    SharedPreferences.setMockInitialValues(_seed());

    final sections = await const SharedPreferencesBackupAdapter().captureSections();
    final reading = sections['reading']! as Map<String, Object?>;
    final bookmarks = sections['bookmarks']! as Map<String, Object?>;
    final notes = sections['notes']! as Map<String, Object?>;

    expect(bookmarks['bookmarks'], <String>['36:1']);
    expect(notes['verse_notes'], contains('2:255'));
    expect(notes['verse_note_sources'], contains('RWD'));
    expect(reading['archive_times'], contains('bookmark|36:1'));
    expect(reading['reader_history_v1'], contains('french_rashid'));
  });

  test('portable restore recreates archive and historical source context', () async {
    SharedPreferences.setMockInitialValues(_seed());
    const adapter = SharedPreferencesBackupAdapter();
    final sections = await adapter.captureSections();

    SharedPreferences.setMockInitialValues(<String, Object>{
      'bookmarks': <String>['1:1'],
      'verse_notes': jsonEncode(<String, String>{'1:1': 'other device'}),
      'reader_history_v1': '[]',
    });
    await adapter.restoreSections(sections);

    final restoredSettings = AppSettings();
    await restoredSettings.load();
    final restoredHistory = await ReaderReadingHistoryRepository.instance.load();

    expect(restoredSettings.bookmarkKeys, contains('36:1'));
    expect(restoredSettings.bookmarkKeys, isNot(contains('1:1')));
    expect(restoredSettings.noteEntries['2:255'], 'private note');
    expect(restoredSettings.noteSourceEntries['2:255'], 'RWD');
    expect(restoredSettings.archiveTimestamp('note', '2:255'), 200);
    expect(restoredHistory, hasLength(1));
    expect(restoredHistory.single.surah, 36);
    expect(restoredHistory.single.ayah, 1);
    expect(restoredHistory.single.sourceId, 'french_rashid');
  });

  test('archive source context is not misclassified as downloadable content', () {
    expect(
      SharedPreferencesBackupAdapter.readingKeys,
      containsAll(<String>['reader_history_v1', 'archive_times']),
    );
    expect(
      SharedPreferencesBackupAdapter.noteKeys,
      containsAll(<String>['verse_notes', 'verse_note_sources']),
    );
    expect(
      SharedPreferencesBackupAdapter.preferenceKeys,
      isNot(contains('offline_audio_pack_cache_v1')),
    );
  });
}
