import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_context.dart';

void main() {
  group('readerSourceIdForArchiveCode', () {
    test('maps Arabic archive code to canonical source id', () {
      expect(readerSourceIdForArchiveCode('AR'), arabicOriginalSourceId);
    });

    test('maps a translation code to its stable catalog id', () {
      final source = translationCatalog.firstWhere((item) => item.code == 'RWD');
      expect(readerSourceIdForArchiveCode('RWD'), source.id);
    });

    test('accepts an already-canonical source id', () {
      final source = translationCatalog.first;
      expect(readerSourceIdForArchiveCode(source.id), source.id);
    });

    test('does not invent a source for unknown legacy codes', () {
      expect(readerSourceIdForArchiveCode('UNKNOWN_SOURCE'), isNull);
    });
  });

  group('parseReaderArchiveContext', () {
    test('keeps canonical ayah identity while restoring note source', () {
      final source = translationCatalog.firstWhere((item) => item.code == 'RWD');
      final context = parseReaderArchiveContext(
        selectionKey: '2:255',
        sourceCode: 'RWD',
        fallbackSourceId: arabicOriginalSourceId,
      );

      expect(context, isNotNull);
      expect(context!.surah, 2);
      expect(context.ayah, 255);
      expect(context.sourceId, source.id);
      expect(context.selectionKey, '2:255');
    });

    test('range and sparse selections reopen at their first canonical ayah', () {
      final range = parseReaderArchiveContext(
        selectionKey: '18:10-12',
        fallbackSourceId: arabicOriginalSourceId,
      );
      final sparse = parseReaderArchiveContext(
        selectionKey: '18:10,15,20',
        fallbackSourceId: arabicOriginalSourceId,
      );

      expect(range?.ayah, 10);
      expect(sparse?.ayah, 10);
    });

    test('falls back to the current display source for legacy bookmarks', () {
      final source = translationCatalog.first;
      final context = parseReaderArchiveContext(
        selectionKey: '36:1',
        fallbackSourceId: source.id,
      );

      expect(context?.sourceId, source.id);
    });

    test('rejects corrupt canonical references instead of guessing', () {
      expect(
        parseReaderArchiveContext(
          selectionKey: '0:1',
          fallbackSourceId: arabicOriginalSourceId,
        ),
        isNull,
      );
      expect(
        parseReaderArchiveContext(
          selectionKey: '2:nope',
          fallbackSourceId: arabicOriginalSourceId,
        ),
        isNull,
      );
      expect(
        parseReaderArchiveContext(
          selectionKey: '115:1',
          fallbackSourceId: arabicOriginalSourceId,
        ),
        isNull,
      );
    });
  });
}
