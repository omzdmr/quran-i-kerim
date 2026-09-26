import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('deleting a practice event recalculates review coverage', () async {
    const progressStore = MemorizationProgressStore();
    const practiceStore = MemorizationPracticeHistoryStore();
    await progressStore.togglePage(15, now: DateTime(2026, 8, 1));

    final recorded = await practiceStore.record(
      page: 15,
      context: MemorizationPracticeContext.soloReview,
      now: DateTime(2026, 9, 22, 9),
    );
    var coverage = buildMemorizationReviewCoverage(
      progress: await progressStore.load(),
      practiceHistory: recorded,
      now: DateTime(2026, 9, 22, 12),
    );
    expect(coverage.freshCount, 1);
    expect(coverage.needsAttentionCount, 0);

    final afterDelete = await practiceStore.remove(recorded.events.single.id);
    coverage = buildMemorizationReviewCoverage(
      progress: await progressStore.load(),
      practiceHistory: afterDelete,
      now: DateTime(2026, 9, 22, 12),
    );
    expect(coverage.neverReviewedCount, 1);
    expect(coverage.needsAttentionCount, 1);
    expect(coverage.items.single.ageDays, 52);
  });
}
