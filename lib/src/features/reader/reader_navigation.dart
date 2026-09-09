import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';

class ReaderNavigationTarget {
  const ReaderNavigationTarget({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}

ReaderNavigationTarget? firstVerseForPage(int page) {
  if (page < 1 || page > 604) return null;
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final value = quran.getPageNumber(surah.number, ayah);
      if (value == page) {
        return ReaderNavigationTarget(surah: surah.number, ayah: ayah);
      }
      if (value > page) return null;
    }
  }
  return null;
}

ReaderNavigationTarget? firstVerseForJuz(int juz) {
  if (juz < 1 || juz > 30) return null;
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final value = quran.getJuzNumber(surah.number, ayah);
      if (value == juz) {
        return ReaderNavigationTarget(surah: surah.number, ayah: ayah);
      }
      if (value > juz) return null;
    }
  }
  return null;
}
