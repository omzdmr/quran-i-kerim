import 'dart:math';

import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';

class MemorizationHintQuestion {
  const MemorizationHintQuestion({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.hintArabic,
    required this.answerArabic,
    required this.hintWordCount,
  });

  final int surah;
  final int ayah;
  final int page;
  final String hintArabic;
  final String answerArabic;
  final int hintWordCount;

  String get id => '$surah:$ayah';
}

List<MemorizationHintQuestion> buildMemorizationHintCandidates(
  Set<int> memorizedPages, {
  int hintWordCount = 2,
}) {
  if (hintWordCount < 1) {
    throw ArgumentError.value(hintWordCount, 'hintWordCount', 'must be positive');
  }
  if (memorizedPages.isEmpty) return const <MemorizationHintQuestion>[];

  final candidates = <MemorizationHintQuestion>[];
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final page = quran.getPageNumber(surah.number, ayah);
      if (!memorizedPages.contains(page)) continue;

      final verse = quran.getVerse(surah.number, ayah).trim();
      final words = verse
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList(growable: false);
      if (words.length <= hintWordCount) continue;

      candidates.add(
        MemorizationHintQuestion(
          surah: surah.number,
          ayah: ayah,
          page: page,
          hintArabic: words.take(hintWordCount).join(' '),
          answerArabic: verse,
          hintWordCount: hintWordCount,
        ),
      );
    }
  }

  return List<MemorizationHintQuestion>.unmodifiable(candidates);
}

MemorizationHintQuestion? pickMemorizationHintQuestion(
  Set<int> memorizedPages, {
  Random? random,
  String? previousId,
  Set<String> preferredIds = const <String>{},
  int hintWordCount = 2,
}) {
  final candidates = buildMemorizationHintCandidates(
    memorizedPages,
    hintWordCount: hintWordCount,
  );
  if (candidates.isEmpty) return null;

  final generator = random ?? Random();
  if (candidates.length == 1) return candidates.first;

  final withoutPrevious = previousId == null
      ? candidates
      : candidates
          .where((question) => question.id != previousId)
          .toList(growable: false);
  var pool = withoutPrevious.isEmpty ? candidates : withoutPrevious;

  if (preferredIds.isNotEmpty) {
    final preferred = pool
        .where((question) => preferredIds.contains(question.id))
        .toList(growable: false);
    if (preferred.isNotEmpty) pool = preferred;
  }

  return pool[generator.nextInt(pool.length)];
}
