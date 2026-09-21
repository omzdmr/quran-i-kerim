import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('portable backup keeps canonical archive and display-source context', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
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
    });

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
