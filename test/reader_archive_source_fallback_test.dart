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
}
