import 'dart:math';

import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';

class MemorizationRecallQuestion {
  const MemorizationRecallQuestion({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.promptArabic,
    required this.answerAyah,
    required this.answerPage,
    required this.answerArabic,
  });

  final int surah;
  final int ayah;
  final int page;
  final String promptArabic;
  final int answerAyah;
  final int answerPage;
  final String answerArabic;

  String get id => '$surah:$ayah';
}

List<MemorizationRecallQuestion> buildMemorizationRecallCandidates(
  Set<int> memorizedPages,
) {
  if (memorizedPages.isEmpty) return const <MemorizationRecallQuestion>[];

  final candidates = <MemorizationRecallQuestion>[];
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah < surah.verseCount; ayah++) {
      final page = quran.getPageNumber(surah.number, ayah);
      final answerPage = quran.getPageNumber(surah.number, ayah + 1);
      if (!memorizedPages.contains(page) ||
          !memorizedPages.contains(answerPage)) {
        continue;
      }

      candidates.add(
        MemorizationRecallQuestion(
          surah: surah.number,
          ayah: ayah,
          page: page,
          promptArabic: quran.getVerse(surah.number, ayah),
          answerAyah: ayah + 1,
          answerPage: answerPage,
          answerArabic: quran.getVerse(surah.number, ayah + 1),
        ),
      );
    }
  }
  return List<MemorizationRecallQuestion>.unmodifiable(candidates);
}

MemorizationRecallQuestion? pickMemorizationRecallQuestion(
  Set<int> memorizedPages, {
  Random? random,
  String? previousId,
  Set<String> preferredIds = const <String>{},
}) {
  final candidates = buildMemorizationRecallCandidates(memorizedPages);
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
