import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';

class MemorizationVerseRef {
  const MemorizationVerseRef({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.arabic,
  });

  final int surah;
  final int ayah;
  final int page;
  final String arabic;

  String get id => '$surah:$ayah';
}

class MemorizationVerseSimilarity {
  const MemorizationVerseSimilarity({
    required this.source,
    required this.candidate,
    required this.score,
    required this.sharedPrefixWords,
    required this.sharedWords,
  });

  final MemorizationVerseRef source;
  final MemorizationVerseRef candidate;
  final double score;
  final int sharedPrefixWords;
  final int sharedWords;
}

final RegExp _arabicMarks = RegExp(
  r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
);
final RegExp _nonArabic = RegExp(r'[^\u0621-\u063A\u0641-\u064A\s]');
final RegExp _whitespace = RegExp(r'\s+');

/// Normalizes Arabic only for local similarity matching.
///
/// The displayed Quran text is never changed. This removes recitation marks,
/// tatweel, punctuation and orthographic hamza/alif variants so a harmless
/// spelling mark does not prevent two otherwise-similar passages from being
/// compared.
String normalizeMemorizationArabic(String value) {
  return value
      .replaceAll(_arabicMarks, '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(_nonArabic, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();
}

List<String> _tokens(String value) {
  final normalized = normalizeMemorizationArabic(value);
  return normalized.isEmpty ? const <String>[] : normalized.split(' ');
}

int _sharedPrefix(List<String> left, List<String> right) {
  final length = left.length < right.length ? left.length : right.length;
  var count = 0;
  while (count < length && left[count] == right[count]) {
    count += 1;
  }
  return count;
}

int _sharedWordCount(List<String> left, List<String> right) {
  final remaining = <String, int>{};
  for (final word in right) {
    remaining[word] = (remaining[word] ?? 0) + 1;
  }

  var count = 0;
  for (final word in left) {
    final available = remaining[word] ?? 0;
    if (available <= 0) continue;
    count += 1;
    if (available == 1) {
      remaining.remove(word);
    } else {
      remaining[word] = available - 1;
    }
  }
  return count;
}

/// Ranks exact Quran-text candidates without claiming scholarly classification.
///
/// Shared opening words are weighted slightly more heavily because verse-entry
/// confusion is especially relevant during memorization. The score is only a
/// study aid, not a tafsir, tajwid or canonical mutashabihat judgment.
List<MemorizationVerseSimilarity> rankSimilarMemorizationVerses({
  required MemorizationVerseRef source,
  required Iterable<MemorizationVerseRef> candidates,
  int limit = 5,
  int minSharedWords = 3,
  double minScore = 0.45,
}) {
  if (limit <= 0) return const <MemorizationVerseSimilarity>[];
  if (minSharedWords < 1) {
    throw ArgumentError.value(minSharedWords, 'minSharedWords');
  }
  if (minScore < 0 || minScore > 1) {
    throw ArgumentError.value(minScore, 'minScore');
  }

  final sourceTokens = _tokens(source.arabic);
  if (sourceTokens.length < minSharedWords) {
    return const <MemorizationVerseSimilarity>[];
  }

  final ranked = <MemorizationVerseSimilarity>[];
  for (final candidate in candidates) {
    if (candidate.id == source.id) continue;
    final candidateTokens = _tokens(candidate.arabic);
    if (candidateTokens.length < minSharedWords) continue;

    final sharedWords = _sharedWordCount(sourceTokens, candidateTokens);
    if (sharedWords < minSharedWords) continue;

    final shorterLength = sourceTokens.length < candidateTokens.length
        ? sourceTokens.length
        : candidateTokens.length;
    final sharedPrefixWords = _sharedPrefix(sourceTokens, candidateTokens);
    final prefixRatio = sharedPrefixWords / shorterLength;
    final overlapRatio = sharedWords / shorterLength;
    final score = (prefixRatio * 0.6) + (overlapRatio * 0.4);
    if (score < minScore) continue;

    ranked.add(
      MemorizationVerseSimilarity(
        source: source,
        candidate: candidate,
        score: score,
        sharedPrefixWords: sharedPrefixWords,
        sharedWords: sharedWords,
      ),
    );
  }

  ranked.sort((left, right) {
    final scoreOrder = right.score.compareTo(left.score);
    if (scoreOrder != 0) return scoreOrder;
    final prefixOrder = right.sharedPrefixWords.compareTo(left.sharedPrefixWords);
    if (prefixOrder != 0) return prefixOrder;
    final sharedOrder = right.sharedWords.compareTo(left.sharedWords);
    if (sharedOrder != 0) return sharedOrder;
    final surahOrder = left.candidate.surah.compareTo(right.candidate.surah);
    if (surahOrder != 0) return surahOrder;
    return left.candidate.ayah.compareTo(right.candidate.ayah);
  });

  if (ranked.length <= limit) return List.unmodifiable(ranked);
  return List.unmodifiable(ranked.take(limit));
}

/// Finds locally available Quran verses that are textually similar to [surah]:[ayah].
///
/// [eligiblePages] can scope results to pages the user has already memorized.
/// Passing null searches the whole bundled Quran text. No network request is
/// performed and no generated religious content is involved.
List<MemorizationVerseSimilarity> findSimilarMemorizationVerses({
  required int surah,
  required int ayah,
  Set<int>? eligiblePages,
  int limit = 5,
  int minSharedWords = 3,
  double minScore = 0.45,
}) {
  final source = MemorizationVerseRef(
    surah: surah,
    ayah: ayah,
    page: quran.getPageNumber(surah, ayah),
    arabic: quran.getVerse(surah, ayah),
  );

  final candidates = <MemorizationVerseRef>[];
  for (final surahInfo in surahCatalog) {
    for (var candidateAyah = 1;
        candidateAyah <= surahInfo.verseCount;
        candidateAyah++) {
      final page = quran.getPageNumber(surahInfo.number, candidateAyah);
      if (eligiblePages != null && !eligiblePages.contains(page)) continue;
      candidates.add(
        MemorizationVerseRef(
          surah: surahInfo.number,
          ayah: candidateAyah,
          page: page,
          arabic: quran.getVerse(surahInfo.number, candidateAyah),
        ),
      );
    }
  }

  return rankSimilarMemorizationVerses(
    source: source,
    candidates: candidates,
    limit: limit,
    minSharedWords: minSharedWords,
    minScore: minScore,
  );
}
