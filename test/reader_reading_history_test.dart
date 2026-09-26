import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reading history keeps latest unique position first', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    await repo.record(surah: 2, ayah: 255, sourceId: 'arabic_original');
    await repo.record(surah: 36, ayah: 1, sourceId: 'arabic_original');
    await repo.record(surah: 2, ayah: 255, sourceId: 'tr_rwwad');

    final items = await repo.load();
    expect(items.length, 2);
    expect(items.first.surah, 2);
    expect(items.first.ayah, 255);
    expect(items.first.sourceId, 'tr_rwwad');
    expect(items[1].surah, 36);
  });

  test('recording a position notifies listening Home surfaces', () async {
    final before = ReaderReadingHistoryRepository.changes.value;

    await ReaderReadingHistoryRepository.instance.record(
      surah: 18,
      ayah: 10,
      sourceId: 'arabic_original',
    );

    expect(ReaderReadingHistoryRepository.changes.value, before + 1);
  });

  test('empty source identity is not persisted or announced', () async {
    final before = ReaderReadingHistoryRepository.changes.value;
    await ReaderReadingHistoryRepository.instance.record(
      surah: 18,
      ayah: 10,
      sourceId: '   ',
    );

    expect(await ReaderReadingHistoryRepository.instance.load(), isEmpty);
    expect(ReaderReadingHistoryRepository.changes.value, before);
  });

  test('recent contexts skip current position and nearby duplicates', () {
    const entries = <ReaderHistoryEntry>[
      ReaderHistoryEntry(
        surah: 2,
        ayah: 255,
        sourceId: 'arabic_original',
        updatedAt: 5,
      ),
      ReaderHistoryEntry(
        surah: 2,
        ayah: 254,
        sourceId: 'arabic_original',
        updatedAt: 4,
      ),
      ReaderHistoryEntry(
        surah: 36,
        ayah: 3,
        sourceId: 'turkish_rwwad',
        updatedAt: 3,
      ),
      ReaderHistoryEntry(
        surah: 36,
        ayah: 1,
        sourceId: 'turkish_rwwad',
        updatedAt: 2,
      ),
      ReaderHistoryEntry(
        surah: 2,
        ayah: 200,
        sourceId: 'turkish_rwwad',
        updatedAt: 1,
      ),
      ReaderHistoryEntry(
        surah: 18,
        ayah: 10,
        sourceId: 'arabic_original',
        updatedAt: 0,
      ),
    ];

    final selected = selectRecentReadingContexts(
      entries,
      currentSurah: 2,
      currentAyah: 255,
      currentSourceId: 'arabic_original',
    );

    expect(
      selected.map((entry) => '${entry.surah}:${entry.ayah}:${entry.sourceId}'),
      <String>[
        '36:3:turkish_rwwad',
        '2:200:turkish_rwwad',
        '18:10:arabic_original',
      ],
    );
  });

  test('reading history caps local history size', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    for (var i = 0; i < 60; i++) {
      await repo.record(surah: (i % 60) + 1, ayah: i + 1, sourceId: 'x');
    }
    expect((await repo.load()).length, ReaderReadingHistoryRepository.maxEntries);
  });

  test('reading history ignores malformed persisted entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: jsonEncode(<Object?>[
        <String, Object>{
          'surah': 2,
          'ayah': 255,
          'sourceId': ' tr_rwwad ',
          'updatedAt': 1234,
        },
        <String, Object>{
          'surah': 0,
          'ayah': 1,
          'sourceId': 'invalid_surah',
          'updatedAt': 1234,
        },
        <String, Object>{
          'surah': 3,
          'ayah': 0,
          'sourceId': 'invalid_ayah',
          'updatedAt': 1234,
        },
        <String, Object>{
          'surah': 36,
          'ayah': 1,
          'sourceId': '   ',
          'updatedAt': 1234,
        },
        'not-an-entry',
      ]),
    });

    final items = await ReaderReadingHistoryRepository.instance.load();
    expect(items, hasLength(1));
    expect(items.single.surah, 2);
    expect(items.single.ayah, 255);
    expect(items.single.sourceId, 'tr_rwwad');
  });

  test('reading history recovers from malformed json', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: '{broken-json',
    });

    expect(await ReaderReadingHistoryRepository.instance.load(), isEmpty);
  });
}
