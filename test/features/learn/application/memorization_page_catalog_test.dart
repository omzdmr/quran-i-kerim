import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_page_catalog.dart';

void main() {
  group('memorization page catalog', () {
    test('covers every Medina mushaf page exactly once in order', () {
      expect(memorizationPageCatalog, hasLength(604));
      expect(
        memorizationPageCatalog.map((entry) => entry.page),
        orderedEquals(List<int>.generate(604, (index) => index + 1)),
      );
    });

    test('page lookup returns the catalog entry and rejects out of range pages', () {
      for (final page in <int>[1, 2, 300, 603, 604]) {
        final info = memorizationPageInfo(page);
        expect(info, isNotNull);
        expect(info!.page, page);
        expect(info.juz, inInclusiveRange(1, 30));
        expect(info.surah, inInclusiveRange(1, 114));
        expect(info.ayah, greaterThanOrEqualTo(1));
      }

      expect(memorizationPageInfo(0), isNull);
      expect(memorizationPageInfo(605), isNull);
    });

    test('juz partitions cover the full catalog without duplicate pages', () {
      final pages = <int>[];
      for (var juz = 1; juz <= 30; juz++) {
        final entries = memorizationPagesForJuz(juz);
        expect(entries, isNotEmpty);
        expect(entries.every((entry) => entry.juz == juz), isTrue);
        pages.addAll(entries.map((entry) => entry.page));
      }

      expect(pages, hasLength(604));
      expect(pages.toSet(), hasLength(604));
      expect(pages.toSet(), memorizationPageCatalog.map((entry) => entry.page).toSet());
      expect(memorizationPagesForJuz(0), isEmpty);
      expect(memorizationPagesForJuz(31), isEmpty);
    });
  });
}
