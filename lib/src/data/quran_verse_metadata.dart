import 'package:quran/quran.dart' as quran;

class QuranVerseMetadata {
  const QuranVerseMetadata({
    required this.surah,
    required this.ayah,
    required this.juz,
    required this.page,
    required this.isSajdah,
  });

  final int surah;
  final int ayah;
  final int juz;
  final int page;
  final bool isSajdah;
}

QuranVerseMetadata quranVerseMetadata(int surah, int ayah) {
  return QuranVerseMetadata(
    surah: surah,
    ayah: ayah,
    juz: quran.getJuzNumber(surah, ayah),
    page: quran.getPageNumber(surah, ayah),
    isSajdah: quran.isSajdahVerse(surah, ayah),
  );
}
