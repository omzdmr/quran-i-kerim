import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_page_catalog.dart';

void main() {
  test('memorization map covers all 604 Mushaf pages exactly once', () {
    expect(memorizationPageCatalog.length, 604);
    expect(
      memorizationPageCatalog.map((item) => item.page).toList(),
      List<int>.generate(604, (index) => index + 1),
    );
    expect(memorizationPageCatalog.first.juz, 1);
    expect(memorizationPageCatalog.last.juz, 30);
  });

  test('every juz exposes at least one page and page lookup is stable', () {
    for (var juz = 1; juz <= 30; juz++) {
      final pages = memorizationPagesForJuz(juz);
      expect(pages, isNotEmpty, reason: 'juz $juz');
      expect(pages.every((page) => page.juz == juz), isTrue);
    }

    expect(memorizationPageInfo(1)?.page, 1);
    expect(memorizationPageInfo(604)?.page, 604);
    expect(memorizationPageInfo(0), isNull);
    expect(memorizationPageInfo(605), isNull);
  });
}
