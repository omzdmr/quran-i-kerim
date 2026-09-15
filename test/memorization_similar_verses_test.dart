import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_similar_verses.dart';

MemorizationVerseRef verse(
  int surah,
  int ayah,
  String arabic, {
  int page = 1,
}) {
  return MemorizationVerseRef(
    surah: surah,
    ayah: ayah,
    page: page,
    arabic: arabic,
  );
}

void main() {
  test('normalization ignores Quran marks, tatweel and alif variants', () {
    expect(
      normalizeMemorizationArabic('إِنَّـا أَعْطَيْنَاكَ'),
      'انا اعطيناك',
    );
  });

  test('longer shared opening ranks ahead of overlap-only candidate', () {
    final source = verse(1, 1, 'قال الذين آمنوا هذا كتاب مبين');
    final prefixMatch = verse(2, 1, 'قال الذين آمنوا هذا وعد كريم');
    final overlapMatch = verse(3, 1, 'هذا كتاب قال قوم الذين آمنوا');

    final result = rankSimilarMemorizationVerses(
      source: source,
      candidates: [overlapMatch, prefixMatch],
      minSharedWords: 3,
      minScore: 0,
    );

    expect(result.map((item) => item.candidate.id), ['2:1', '3:1']);
    expect(result.first.sharedPrefixWords, 4);
  });

  test('source verse is excluded and weak matches stay out', () {
    final source = verse(1, 1, 'هذا نص طويل فيه كلمات مشتركة');
    final strong = verse(2, 1, 'هذا نص طويل فيه كلمات اخرى');
    final weak = verse(3, 1, 'هذا نص مختلف تماما هنا');

    final result = rankSimilarMemorizationVerses(
      source: source,
      candidates: [source, weak, strong],
      minSharedWords: 3,
      minScore: 0.45,
    );

    expect(result, hasLength(1));
    expect(result.single.candidate.id, '2:1');
  });

  test('ranking is deterministic and obeys limit', () {
    final source = verse(10, 5, 'قال ربنا اننا آمنا فاغفر لنا');
    final candidates = [
      verse(4, 2, 'قال ربنا اننا آمنا وارحمنا'),
      verse(3, 9, 'قال ربنا اننا آمنا فاهدنا'),
      verse(7, 1, 'قال ربنا اننا آمنا فانصرنا'),
    ];

    final result = rankSimilarMemorizationVerses(
      source: source,
      candidates: candidates,
      limit: 2,
      minSharedWords: 3,
      minScore: 0,
    );

    expect(result.map((item) => item.candidate.id), ['3:9', '4:2']);
  });

  test('short source does not invent a similar-verse result', () {
    final result = rankSimilarMemorizationVerses(
      source: verse(1, 1, 'الله احد'),
      candidates: [verse(2, 1, 'الله احد حق')],
      minSharedWords: 3,
    );

    expect(result, isEmpty);
  });
}
