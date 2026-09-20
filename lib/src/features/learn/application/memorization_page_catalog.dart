import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';

class MemorizationPageInfo {
  const MemorizationPageInfo({
    required this.page,
    required this.juz,
    required this.surah,
    required this.ayah,
  });

  final int page;
  final int juz;
  final int surah;
  final int ayah;
}

List<MemorizationPageInfo> _buildPageCatalog() {
  final byPage = <int, MemorizationPageInfo>{};
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final page = quran.getPageNumber(surah.number, ayah);
      byPage.putIfAbsent(
        page,
        () => MemorizationPageInfo(
          page: page,
          juz: quran.getJuzNumber(surah.number, ayah),
          surah: surah.number,
          ayah: ayah,
        ),
      );
    }
  }

  final pages = <MemorizationPageInfo>[];
  for (var page = 1; page <= 604; page++) {
    final info = byPage[page];
    if (info != null) pages.add(info);
  }
  return List<MemorizationPageInfo>.unmodifiable(pages);
}

final List<MemorizationPageInfo> memorizationPageCatalog = _buildPageCatalog();

List<MemorizationPageInfo> memorizationPagesForJuz(int juz) {
  if (juz < 1 || juz > 30) return const <MemorizationPageInfo>[];
  return memorizationPageCatalog.where((page) => page.juz == juz).toList();
}

MemorizationPageInfo? memorizationPageInfo(int page) {
  if (page < 1 || page > memorizationPageCatalog.length) return null;
  final candidate = memorizationPageCatalog[page - 1];
  return candidate.page == page ? candidate : null;
}
