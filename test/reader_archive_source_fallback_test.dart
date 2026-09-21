import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_context.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';

void main() {
  test('empty history source cannot mask a valid current source', () {
    final context = parseReaderArchiveContext(
      selectionKey: '2:255',
      historySourceId: '   ',
      fallbackSourceId: arabicOriginalSourceId,
    );
    expect(context?.sourceId, arabicOriginalSourceId);
  });

  test('source recovery skips corrupt empty history entries', () {
    final source = recentReaderSourceForArchive(
      '36:1',
      const <ReaderHistoryEntry>[
        ReaderHistoryEntry(
          surah: 36,
          ayah: 1,
          sourceId: '   ',
          updatedAt: 300,
        ),
        ReaderHistoryEntry(
          surah: 36,
          ayah: 1,
          sourceId: 'english_rwwad',
          updatedAt: 200,
        ),
      ],
    );
    expect(source, englishTranslationId);
  });

  test('saved reference cannot point beyond the surah verse count', () {
    expect(parseReaderArchiveReference('1:8'), isNull);
    expect(parseReaderArchiveReference('2:287'), isNull);
    expect(parseReaderArchiveReference('1:7')?.ayah, 7);
    expect(parseReaderArchiveReference('2:286')?.ayah, 286);
  });
}
