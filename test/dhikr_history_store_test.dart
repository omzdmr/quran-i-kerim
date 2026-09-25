import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_history_store.dart';

void main() {
  const codec = DhikrCounterDocumentCodec();

  test('migrates legacy flat count document without losing totals', () {
    final document = codec.decode('{"subhanallah":33,"salawat":12}');
    expect(document.counts, <String, int>{'subhanallah': 33, 'salawat': 12});
    expect(document.history, isEmpty);
  });

  test('archives a completed day and round trips v2 document', () {
    final history = codec.archiveDay(
      history: const <DhikrDailyHistoryRecord>[],
      dateKey: '2026-09-25',
      counts: const <String, int>{'subhanallah': 33, 'custom_1': 7},
      customLabels: const <String, String>{'custom_1': 'Private reminder'},
    );
    final encoded = codec.encode(
      counts: const <String, int>{'subhanallah': 40},
      history: history,
    );
    final restored = codec.decode(encoded);

    expect(restored.counts['subhanallah'], 40);
    expect(restored.history, hasLength(1));
    expect(restored.history.single.total, 40);
    expect(restored.history.single.customLabels['custom_1'], 'Private reminder');
  });

  test('same date is replaced instead of duplicated', () {
    final first = codec.archiveDay(
      history: const <DhikrDailyHistoryRecord>[],
      dateKey: '2026-09-25',
      counts: const <String, int>{'subhanallah': 10},
    );
    final second = codec.archiveDay(
      history: first,
      dateKey: '2026-09-25',
      counts: const <String, int>{'subhanallah': 11},
    );
    expect(second, hasLength(1));
    expect(second.single.total, 11);
  });

  test('malformed history fails closed without corrupting app state', () {
    final document = codec.decode(
      '{"formatVersion":2,"counts":{"subhanallah":2},"history":[{"date":"bad","counts":{"subhanallah":1}}]}',
    );
    expect(document.counts, isEmpty);
    expect(document.history, isEmpty);
  });

  test('history does not silently discard older user days', () {
    var history = const <DhikrDailyHistoryRecord>[];
    for (var index = 0; index < 370; index++) {
      final date = DateTime.utc(2025, 1, 1).add(Duration(days: index));
      final key = date.toIso8601String().substring(0, 10);
      history = codec.archiveDay(
        history: history,
        dateKey: key,
        counts: const <String, int>{'subhanallah': 1},
      );
    }
    expect(history, hasLength(370));
  });
}
