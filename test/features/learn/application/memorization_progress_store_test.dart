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
}
