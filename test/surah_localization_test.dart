import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/surah_localization.dart';

void main() {
  test('reader surah names follow source language', () {
    expect(localizedSurahName(33, 'tr'), 'Ahzâb');
    expect(localizedSurahName(31, 'az'), 'Loğman');
    expect(localizedSurahName(33, 'en').toLowerCase(), contains('ahzab'));
    expect(localizedSurahName(1, 'ar'), 'الفاتحة');
    expect(localizedSurahName(74, 'ru'), isNotEmpty);
  });

  test('search aliases include active and cross-language names', () {
    final aliases = surahSearchAliases(33, 'en').map((e) => e.toLowerCase());
    expect(aliases.any((value) => value.contains('ahzab')), isTrue);
    expect(surahSearchAliases(33, 'az'), contains('Əhzab'));
    expect(surahSearchAliases(33, 'tr'), contains('Ahzâb'));
  });
}
