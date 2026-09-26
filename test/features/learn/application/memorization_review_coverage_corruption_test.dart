import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coverage survives malformed local review metadata', () async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['12', 'bad', '999'],
      'memorization_page_progress_v1': '{not-json',
      'memorization_practice_history_v1': '[{"broken":true}]',
    });

    const store = MemorizationReviewCoverageStore();
    final coverage = await store.load(now: DateTime(2026, 9, 22));

    expect(coverage.total, 1);
    expect(coverage.items.single.page, 12);
    expect(
      coverage.items.single.freshness,
      MemorizationReviewFreshness.neverReviewed,
    );
  });
}
