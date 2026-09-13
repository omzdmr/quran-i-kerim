import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_i_kerim/src/features/learn/application/memorization_target_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_target_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('full Quran target covers all 604 Mushaf pages', () {
    final pages = memorizationPagesForTarget(MemorizationTargetId.fullQuran);
    expect(pages.length, 604);
    expect(pages.first, 1);
    expect(pages.last, 604);
  });

  test('Juz Amma target contains surahs 78 through 114', () {
    final target = memorizationTargetDefinition(MemorizationTargetId.juzAmma);
    expect(target.surahNumbers.first, 78);
    expect(target.surahNumbers.last, 114);
    expect(target.surahNumbers, isNot(contains(77)));
    expect(target.surahNumbers.length, 37);
  });

  test('short surah targets expose their Quran verse counts', () {
    expect(
      memorizationTargetDefinition(MemorizationTargetId.alMulk).verseCount,
      30,
    );
    expect(
      memorizationTargetDefinition(MemorizationTargetId.arRahman).verseCount,
      78,
    );
    expect(
      memorizationTargetDefinition(MemorizationTargetId.yaSin).verseCount,
      83,
    );
    expect(
      memorizationTargetDefinition(MemorizationTargetId.alKahf).verseCount,
      110,
    );
  });

  test('next target page skips pages already memorized', () {
    final pages = memorizationPagesForTarget(MemorizationTargetId.alMulk);
    expect(pages.length, greaterThan(1));

    final next = nextMemorizationPageForTarget(
      MemorizationTargetId.alMulk,
      <int>{pages.first},
    );
    expect(next, pages[1]);
  });

  test('target selection persists locally and defaults to full Quran', () async {
    const store = MemorizationTargetStore();
    expect(await store.load(), MemorizationTargetId.fullQuran);

    await store.save(MemorizationTargetId.juzAmma);
    expect(await store.load(), MemorizationTargetId.juzAmma);

    await store.clear();
    expect(await store.load(), MemorizationTargetId.fullQuran);
  });
}
