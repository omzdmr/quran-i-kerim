import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_search.dart';

void main() {
  test('matches canonical surah:ayah references offline', () {
    expect(
      readerArchiveMatchesQuery(
        query: '2:255',
        selectionKey: '2:255',
        languageCode: 'en',
      ),
      isTrue,
    );
  });

  test('matches localized surah name plus ayah as AND terms', () {
    expect(
      readerArchiveMatchesQuery(
        query: 'bakara 255',
        selectionKey: '2:255',
        languageCode: 'tr',
      ),
      isTrue,
    );
    expect(
      readerArchiveMatchesQuery(
        query: 'bakara 256',
        selectionKey: '2:255',
        languageCode: 'tr',
      ),
      isFalse,
    );
  });

  test('matches private note text locally without indexing it elsewhere', () {
    expect(
      readerArchiveMatchesQuery(
        query: 'patience reminder',
        selectionKey: '94:5',
        languageCode: 'en',
        note: 'Patience reminder for difficult days',
      ),
      isTrue,
    );
  });

  test('matches source code and ignores surrounding whitespace/case', () {
    expect(
      readerArchiveMatchesQuery(
        query: '  rWd-En ',
        selectionKey: '2:255',
        languageCode: 'en',
        sourceCode: 'RWD-EN',
      ),
      isTrue,
    );
  });

  test('empty query leaves all saved items visible', () {
    expect(
      readerArchiveMatchesQuery(
        query: '   ',
        selectionKey: '36:1',
        languageCode: 'fr',
      ),
      isTrue,
    );
  });
}
