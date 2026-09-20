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
          'sourceId': 'tr_rwwad',
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
        'not-an-entry',
      ]),
    });

    final items = await ReaderReadingHistoryRepository.instance.load();
    expect(items, hasLength(1));
    expect(items.single.surah, 2);
    expect(items.single.ayah, 255);
    expect(items.single.sourceId, 'tr_rwwad');
  });
  test('notifies listeners after history changes', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    var notifications = 0;
    void listener() => notifications++;
    ReaderReadingHistoryRepository.changes.addListener(listener);
    addTearDown(
      () => ReaderReadingHistoryRepository.changes.removeListener(listener),
    );

    await repo.record(surah: 1, ayah: 1, sourceId: 'arabic_original');
    await repo.clear();

    expect(notifications, 2);
  });

  test('reading history recovers from malformed json', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderReadingHistoryRepository.storageKey: '{broken-json',
    });

    expect(await ReaderReadingHistoryRepository.instance.load(), isEmpty);
  });
}
