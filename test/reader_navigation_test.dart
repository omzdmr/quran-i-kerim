import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/reader/reader_navigation.dart';

void main() {
  test('page navigation resolves to a verse on the requested page', () {
    final first = firstVerseForPage(1);
    expect(first, isNotNull);
    expect(quran.getPageNumber(first!.surah, first.ayah), 1);

    final middle = firstVerseForPage(302);
    expect(middle, isNotNull);
    expect(quran.getPageNumber(middle!.surah, middle.ayah), 302);
  });

  test('juz navigation resolves to a verse in the requested juz', () {
    final target = firstVerseForJuz(15);
    expect(target, isNotNull);
    expect(quran.getJuzNumber(target!.surah, target.ayah), 15);
  });

  test('navigation rejects out of range values', () {
    expect(firstVerseForPage(0), isNull);
    expect(firstVerseForPage(605), isNull);
    expect(firstVerseForJuz(0), isNull);
    expect(firstVerseForJuz(31), isNull);
  });
}
