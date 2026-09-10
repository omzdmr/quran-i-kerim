import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_verse_metadata.dart';
import 'package:quran_i_kerim/src/data/surah_localization.dart';

void main() {
  test('reader surah names follow source language', () {
    expect(localizedSurahName(33, 'tr'), 'Ahzâb');
    expect(localizedSurahName(31, 'az'), 'Loğman');
    expect(localizedSurahName(33, 'en').toLowerCase(), contains('ahzab'));
    expect(localizedSurahName(1, 'ar'), 'الفاتحة');
    expect(localizedSurahName(74, 'ru'), isNotEmpty);
    expect(localizedSurahName(2, 'fa'), 'بقره');
    expect(localizedSurahName(33, 'fa'), 'احزاب');
    expect(localizedSurahName(114, 'fa'), 'ناس');
  });

  test('quran metadata exposes local juz page and sajdah data', () {
    final first = quranVerseMetadata(1, 1);
    expect(first.juz, 1);
    expect(first.page, 1);
    expect(first.isSajdah, isFalse);

    final sajdah = quranVerseMetadata(96, 19);
    expect(sajdah.juz, inInclusiveRange(1, 30));
    expect(sajdah.page, inInclusiveRange(1, 604));
    expect(sajdah.isSajdah, isTrue);
  });

  test('search aliases include active and cross-language names', () {
    final aliases = surahSearchAliases(33, 'en').map((e) => e.toLowerCase());
    expect(aliases.any((value) => value.contains('ahzab')), isTrue);
    expect(surahSearchAliases(33, 'az'), contains('Əhzab'));
    expect(surahSearchAliases(33, 'tr'), contains('Ahzâb'));
    expect(surahSearchAliases(33, 'fa'), contains('احزاب'));
  });
}
