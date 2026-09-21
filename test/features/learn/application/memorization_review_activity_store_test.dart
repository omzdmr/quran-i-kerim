import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('review activity updates age without inventing assessment', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(25, now: DateTime(2026, 8, 1));

    final updated = await store.recordReviewActivity(
      25,
      now: DateTime(2026, 9, 22, 10),
    );
    final page = updated.progressForPage(25)!;

    expect(page.lastReviewedAt, DateTime(2026, 9, 22, 10));
    expect(page.selfAssessment, isNull);
    expect(updated.practiceDays, contains('2026-09-22'));
  });

  test('review activity preserves an existing quality assessment', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(26, now: DateTime(2026, 8, 1));
    await store.recordReview(
      26,
      selfAssessment: MemorizationSelfAssessment.struggled,
      now: DateTime(2026, 9, 1),
    );

    final updated = await store.recordReviewActivity(
      26,
      now: DateTime(2026, 9, 22),
    );

    expect(
      updated.progressForPage(26)!.selfAssessment,
      MemorizationSelfAssessment.struggled,
    );
    expect(updated.progressForPage(26)!.lastReviewedAt, DateTime(2026, 9, 22));
  });

  test('review activity does not create progress for an unmemorized page', () async {
    const store = MemorizationProgressStore();
    final updated = await store.recordReviewActivity(
      27,
      now: DateTime(2026, 9, 22),
    );

    expect(updated.containsPage(27), isFalse);
    expect(updated.progressForPage(27), isNull);
  });
}
