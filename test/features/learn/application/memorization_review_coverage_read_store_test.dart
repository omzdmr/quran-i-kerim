import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('read store joins persisted progress and practice history', () async {
    const progress = MemorizationProgressStore();
    const practice = MemorizationPracticeHistoryStore();
    const coverageStore = MemorizationReviewCoverageStore();

    await progress.togglePage(30, now: DateTime(2026, 8, 1));
    await progress.togglePage(31, now: DateTime(2026, 8, 2));
    await practice.record(
      page: 31,
      context: MemorizationPracticeContext.recitedToSomeone,
      now: DateTime(2026, 9, 21),
    );

    final coverage = await coverageStore.load(now: DateTime(2026, 9, 22));

    expect(coverage.total, 2);
    expect(coverage.needsAttentionCount, 1);
    expect(coverage.items.first.page, 30);
    expect(coverage.items.last.page, 31);
    expect(
      coverage.items.last.freshness,
      MemorizationReviewFreshness.fresh,
    );
  });
}
