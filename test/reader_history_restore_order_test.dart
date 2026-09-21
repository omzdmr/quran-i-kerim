import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restored history is normalized newest-first before UI/source recovery', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: jsonEncode(<Object>[
        <String, Object>{
          'surah': 36,
          'ayah': 1,
          'sourceId': 'old_source',
          'updatedAt': 100,
        },
        <String, Object>{
          'surah': 18,
          'ayah': 10,
          'sourceId': 'new_source',
          'updatedAt': 300,
        },
        <String, Object>{
          'surah': 2,
          'ayah': 255,
          'sourceId': 'middle_source',
          'updatedAt': 200,
        },
      ]),
    });

    final history = await ReaderReadingHistoryRepository.instance.load();
    expect(history.map((entry) => entry.updatedAt), <int>[300, 200, 100]);
    expect(history.first.sourceId, 'new_source');
  });
}
