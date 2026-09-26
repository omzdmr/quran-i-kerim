import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recording a review moves a memorized page out of untouched coverage', () async {
    const store = MemorizationProgressStore();
    final memorizedAt = DateTime(2026, 8, 1, 9);
    await store.togglePage(12, now: memorizedAt);

    var snapshot = await store.load();
    var coverage = buildMemorizationReviewCoverage(
      progress: snapshot,
      now: DateTime(2026, 9, 22),
    );
    expect(coverage.neverReviewedCount, 1);
    expect(coverage.items.single.page, 12);

    await store.recordReview(
      12,
      selfAssessment: MemorizationSelfAssessment.independent,
      now: DateTime(2026, 9, 22, 10),
    );

    snapshot = await store.load();
    coverage = buildMemorizationReviewCoverage(
      progress: snapshot,
      now: DateTime(2026, 9, 22, 20),
    );
    expect(coverage.neverReviewedCount, 0);
    expect(coverage.freshCount, 1);
    expect(coverage.items.single.ageDays, 0);
    expect(
      coverage.items.single.selfAssessment,
      MemorizationSelfAssessment.independent,
    );
  });

  test('review age survives a new store load', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(33, now: DateTime(2026, 8, 1));
    await store.recordReview(
      33,
      selfAssessment: MemorizationSelfAssessment.assisted,
      now: DateTime(2026, 9, 1),
    );

    final reloaded = await const MemorizationProgressStore().load();
    final coverage = buildMemorizationReviewCoverage(
      progress: reloaded,
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.overdueCount, 1);
    expect(coverage.items.single.ageDays, 21);
    expect(
      coverage.items.single.selfAssessment,
      MemorizationSelfAssessment.assisted,
    );
  });
}
