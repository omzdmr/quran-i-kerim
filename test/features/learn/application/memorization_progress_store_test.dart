import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load drops a review timestamp older than memorization', () async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['5'],
      'memorization_page_progress_v1': jsonEncode({
        '5': {
          'memorizedAt': '2026-09-10T08:00:00.000',
          'lastReviewedAt': '2026-09-09T08:00:00.000',
          'selfAssessment': 'independent',
        },
      }),
    });

    const store = MemorizationProgressStore();
    final snapshot = await store.load();

    final progress = snapshot.progressForPage(5);
    expect(progress?.memorizedAt, DateTime(2026, 9, 10, 8));
    expect(progress?.lastReviewedAt, isNull);
    expect(
      progress?.selfAssessment,
      MemorizationSelfAssessment.independent,
    );

    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(
      prefs.getString('memorization_page_progress_v1')!,
    ) as Map<String, dynamic>;
    expect((persisted['5'] as Map<String, dynamic>)['lastReviewedAt'], isNull);
  });

  test('memorized page and review metadata survive reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationProgressStore();
    final memorizedAt = DateTime(2026, 9, 10, 8, 30);
    final reviewedAt = DateTime(2026, 9, 12, 19, 15);

    await store.togglePage(12, now: memorizedAt);
    await store.recordReview(
      12,
      selfAssessment: MemorizationSelfAssessment.independent,
      now: reviewedAt,
    );

    final reloaded = await const MemorizationProgressStore().load();
    final progress = reloaded.progressForPage(12);

    expect(reloaded.memorizedPages, <int>{12});
    expect(reloaded.practiceDays, <String>{'2026-09-10', '2026-09-12'});
    expect(progress?.memorizedAt, memorizedAt);
    expect(progress?.lastReviewedAt, reviewedAt);
    expect(progress?.selfAssessment, MemorizationSelfAssessment.independent);
  });

  test('unmemorizing a page removes its persisted progress metadata', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = MemorizationProgressStore();

    await store.togglePage(7, now: DateTime(2026, 9, 10));
    await store.recordSelfAssessment(
      7,
      selfAssessment: MemorizationSelfAssessment.assisted,
      now: DateTime(2026, 9, 11),
    );
    await store.togglePage(7, now: DateTime(2026, 9, 12));

    final reloaded = await const MemorizationProgressStore().load();
    expect(reloaded.containsPage(7), isFalse);
    expect(reloaded.progressForPage(7), isNull);

    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(
      prefs.getString('memorization_page_progress_v1')!,
    ) as Map<String, dynamic>;
    expect(persisted.containsKey('7'), isFalse);
  });
}
