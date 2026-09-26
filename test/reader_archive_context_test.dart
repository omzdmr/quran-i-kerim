import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_context.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';

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

  group('archive reference and historical source recovery', () {
    test('parses range and sparse selection references canonically', () {
      expect(parseReaderArchiveReference('18:10-12')?.ayah, 10);
      expect(parseReaderArchiveReference('18:10,15,20')?.ayah, 10);
      expect(parseReaderArchiveReference('115:1'), isNull);
    });

    test('chooses newest exact-ayah history source for legacy bookmarks', () {
      final source = recentReaderSourceForArchive('36:1', <ReaderHistoryEntry>[
        const ReaderHistoryEntry(
          surah: 36,
          ayah: 1,
          sourceId: 'english_rwwad',
          updatedAt: 100,
        ),
        const ReaderHistoryEntry(
          surah: 36,
          ayah: 1,
          sourceId: 'french_rashid',
          updatedAt: 200,
        ),
        const ReaderHistoryEntry(
          surah: 36,
          ayah: 2,
          sourceId: 'arabic_original',
          updatedAt: 300,
        ),
      ]);

      expect(source, 'french_rashid');
    });

    test('does not borrow source from a neighbouring ayah', () {
      expect(
        recentReaderSourceForArchive(
          '36:1',
          const <ReaderHistoryEntry>[
            ReaderHistoryEntry(
              surah: 36,
              ayah: 2,
              sourceId: 'english_rwwad',
              updatedAt: 100,
            ),
          ],
        ),
        isNull,
      );
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

    test('explicit note source wins over history and current source', () {
      final context = parseReaderArchiveContext(
        selectionKey: '2:255',
        sourceCode: 'RWD-EN',
        historySourceId: 'french_rashid',
        fallbackSourceId: arabicOriginalSourceId,
      );
      expect(context?.sourceId, englishTranslationId);
    });

    test('history source wins over current source for legacy saved items', () {
      final context = parseReaderArchiveContext(
        selectionKey: '36:1',
        historySourceId: 'french_rashid',
        fallbackSourceId: arabicOriginalSourceId,
      );
      expect(context?.sourceId, 'french_rashid');
    });

    test('falls back to the current display source without history', () {
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
