import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('oversized restored history keeps only the newest local contexts', () async {
    final rows = <Map<String, Object>>[];
    for (var i = 0; i < 80; i++) {
      rows.add(<String, Object>{
        'surah': (i % 60) + 1,
        'ayah': 1,
        'sourceId': 'source_$i',
        'updatedAt': i,
      });
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: jsonEncode(rows),
    });

    final history = await ReaderReadingHistoryRepository.instance.load();
    expect(history, hasLength(ReaderReadingHistoryRepository.maxEntries));
    expect(history.first.updatedAt, 79);
    expect(history.last.updatedAt, 30);
  });
}
