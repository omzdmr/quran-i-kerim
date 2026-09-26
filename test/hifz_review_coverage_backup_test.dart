import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const adapter = SharedPreferencesBackupAdapter();

  test('Hifz review freshness and practice history survive backup round trip', () async {
    const pageProgress =
        '{"42":{"memorizedAt":"2026-08-01T00:00:00.000",'
        '"lastReviewedAt":"2026-09-20T12:00:00.000",'
        '"selfAssessment":"independent"}}';
    const practiceHistory =
        '[{"id":"practice-42","page":42,"context":"soloReview",'
        '"occurredAt":"2026-09-21T12:00:00.000"}]';

    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['42'],
      'memorization_page_progress_v1': pageProgress,
      'memorization_practice_history_v1': practiceHistory,
    });

    final sections = await adapter.captureSections();
    expect(
      (sections['memorization'] as Map)['memorization_page_progress_v1'],
      pageProgress,
    );
    expect(
      (sections['memorizationPractice'] as Map)
          ['memorization_practice_history_v1'],
      practiceHistory,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);
    final restored = await SharedPreferences.getInstance();

    expect(restored.getStringList('memorized_pages_v1'), <String>['42']);
    expect(restored.getString('memorization_page_progress_v1'), pageProgress);
    expect(
      restored.getString('memorization_practice_history_v1'),
      practiceHistory,
    );
  });
}
