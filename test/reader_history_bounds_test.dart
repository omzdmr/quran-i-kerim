import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('record clamps navigation history to the surah final ayah', () async {
    await ReaderReadingHistoryRepository.instance.record(
      surah: 1,
      ayah: 999,
      sourceId: 'arabic_original',
    );
    await ReaderReadingHistoryRepository.instance.record(
      surah: 2,
      ayah: 999,
      sourceId: 'english_rwwad',
    );

    final entries = await ReaderReadingHistoryRepository.instance.load();
    expect(entries, hasLength(2));
    expect(entries.first.surah, 2);
    expect(entries.first.ayah, 286);
    expect(entries.last.surah, 1);
    expect(entries.last.ayah, 7);
  });

  test('load drops persisted ayahs beyond canonical surah bounds', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: jsonEncode(<Object>[
        <String, Object>{
          'surah': 1,
          'ayah': 8,
          'sourceId': 'arabic_original',
          'updatedAt': 2,
        },
        <String, Object>{
          'surah': 1,
          'ayah': 7,
          'sourceId': 'arabic_original',
          'updatedAt': 1,
        },
      ]),
    });

    final entries = await ReaderReadingHistoryRepository.instance.load();
    expect(entries, hasLength(1));
    expect(entries.single.ayah, 7);
  });
}
