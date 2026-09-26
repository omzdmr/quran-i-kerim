import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const progressStore = MemorizationProgressStore();
  const coverageStore = MemorizationReviewCoverageStore();

  test('finishing first bounded batch exposes deferred pages as the next batch',
      () async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1', '2', '3', '4', '5', '6', '7', '8'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"3":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"4":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"5":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"6":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"7":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"8":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });

    final firstCoverage = await coverageStore.load(
      now: DateTime(2026, 9, 22),
    );
    final firstSession = buildMemorizationReviewSession(coverage: firstCoverage);
    expect(firstSession.pages, [1, 2, 3, 4, 5]);
    expect(firstSession.deferredCount, 3);

    for (final page in firstSession.pages) {
      await progressStore.recordReview(
        page,
        selfAssessment: MemorizationSelfAssessment.independent,
        now: DateTime(2026, 9, 22, 8, page),
      );
    }

    final secondCoverage = await coverageStore.load(
      now: DateTime(2026, 9, 22, 9),
    );
    final secondSession = buildMemorizationReviewSession(coverage: secondCoverage);

    expect(secondSession.pages, [6, 7, 8]);
    expect(secondSession.totalAttentionPages, 3);
    expect(secondSession.deferredCount, 0);
    expect(secondCoverage.freshCount, 5);
  });

  test('a struggled review is persisted as user assessment', () async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['12'],
      'memorization_page_progress_v1':
          '{"12":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });

    await progressStore.recordReview(
      12,
      selfAssessment: MemorizationSelfAssessment.struggled,
      now: DateTime(2026, 9, 22, 10),
    );

    final coverage = await coverageStore.load(now: DateTime(2026, 9, 22, 10, 1));
    final page = coverage.items.single;
    expect(page.selfAssessment, MemorizationSelfAssessment.struggled);
    expect(page.lastReviewedAt, DateTime(2026, 9, 22, 10));
  });
}
