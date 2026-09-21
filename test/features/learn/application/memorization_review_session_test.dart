import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_session.dart';

MemorizationReviewCoverageItem item(
  int page,
  MemorizationReviewFreshness freshness, {
  int? ageDays,
}) =>
    MemorizationReviewCoverageItem(
      page: page,
      freshness: freshness,
      ageDays: ageDays,
      lastReviewedAt: null,
      selfAssessment: null,
    );

void main() {
  test('bounds an overdue backlog without hiding deferred work', () {
    final items = <MemorizationReviewCoverageItem>[
      for (var page = 1; page <= 8; page++)
        item(page, MemorizationReviewFreshness.overdue, ageDays: 20 + page),
    ];
    final coverage = MemorizationReviewCoverage(
      items: items,
      neverReviewedCount: 0,
      overdueCount: 8,
      agingCount: 0,
      freshCount: 0,
    );

    final session = buildMemorizationReviewSession(coverage: coverage);

    expect(session.pages, [1, 2, 3, 4, 5]);
    expect(session.sessionSize, 5);
    expect(session.totalAttentionPages, 8);
    expect(session.deferredCount, 3);
  });

  test('excludes aging and fresh pages from the urgent session', () {
    final coverage = MemorizationReviewCoverage(
      items: [
        item(9, MemorizationReviewFreshness.overdue, ageDays: 18),
        item(10, MemorizationReviewFreshness.aging, ageDays: 9),
        item(11, MemorizationReviewFreshness.fresh, ageDays: 2),
      ],
      neverReviewedCount: 0,
      overdueCount: 1,
      agingCount: 1,
      freshCount: 1,
    );

    final session = buildMemorizationReviewSession(coverage: coverage);
    expect(session.pages, [9]);
    expect(session.deferredCount, 0);
  });

  test('rejects an invalid session size', () {
    final coverage = MemorizationReviewCoverage(
      items: const [],
      neverReviewedCount: 0,
      overdueCount: 0,
      agingCount: 0,
      freshCount: 0,
    );

    expect(
      () => buildMemorizationReviewSession(coverage: coverage, maxPages: 0),
      throwsArgumentError,
    );
  });
}
