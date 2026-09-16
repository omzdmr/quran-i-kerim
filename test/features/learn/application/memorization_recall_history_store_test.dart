import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_recall_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('manual weak marking persists without inventing a recall attempt', () async {
    const store = MemorizationRecallHistoryStore();

    final marked = await store.setManuallyWeak('2:6', weak: true);
    final stat = marked.statFor('2:6');

    expect(stat?.manuallyWeak, isTrue);
    expect(stat?.difficulty, 0);
    expect(stat?.priorityDifficulty, 1);
    expect(stat?.attempts, 0);
    expect(stat?.lastAttemptAt, isNull);

    final restored = await store.load();
    expect(restored.manuallyWeakQuestionIds, contains('2:6'));
    expect(restored.weakQuestionIds, contains('2:6'));
  });

  test('clearing manual weak marking preserves assessment-derived difficulty', () async {
    const store = MemorizationRecallHistoryStore();

    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime.utc(2026, 9, 15, 10),
    );
    await store.setManuallyWeak('2:6', weak: true);
    final cleared = await store.setManuallyWeak('2:6', weak: false);

    final stat = cleared.statFor('2:6');
    expect(stat?.manuallyWeak, isFalse);
    expect(stat?.difficulty, 2);
    expect(stat?.attempts, 1);
    expect(cleared.weakQuestionIds, contains('2:6'));
  });

  test('clearing a manual-only weak marking removes its synthetic entry', () async {
    const store = MemorizationRecallHistoryStore();

    await store.setManuallyWeak('2:6', weak: true);
    final cleared = await store.setManuallyWeak('2:6', weak: false);

    expect(cleared.statFor('2:6'), isNull);
    expect((await store.load()).statFor('2:6'), isNull);
  });

  test('assessments update difficulty, attempts and persisted timestamp', () async {
    const store = MemorizationRecallHistoryStore();
    final firstAt = DateTime.utc(2026, 9, 15, 10);
    final secondAt = DateTime.utc(2026, 9, 16, 10);

    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.struggled,
      now: firstAt,
    );
    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.assisted,
      now: secondAt,
    );

    final restored = await store.load();
    final stat = restored.statFor('2:6');
    expect(stat?.difficulty, 3);
    expect(stat?.attempts, 2);
    expect(stat?.lastAttemptAt, secondAt);
    expect(restored.weakQuestionIds, contains('2:6'));
  });

  test('independent recall reduces difficulty without going below zero', () async {
    const store = MemorizationRecallHistoryStore();

    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime.utc(2026, 9, 14),
    );
    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.independent,
      now: DateTime.utc(2026, 9, 15),
    );
    final recovered = await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.independent,
      now: DateTime.utc(2026, 9, 16),
    );

    expect(recovered.statFor('2:6')?.difficulty, 0);
    expect(recovered.statFor('2:6')?.attempts, 3);
    expect(recovered.weakQuestionIds, isNot(contains('2:6')));

    final extraIndependent = await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.independent,
      now: DateTime.utc(2026, 9, 17),
    );
    expect(extraIndependent.statFor('2:6')?.difficulty, 0);
  });

  test('weak stats prioritize difficulty then oldest attempt', () async {
    const store = MemorizationRecallHistoryStore();

    await store.setManuallyWeak('manual', weak: true);
    await store.recordAssessment(
      'older',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime.utc(2026, 9, 10),
    );
    await store.recordAssessment(
      'newer',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime.utc(2026, 9, 12),
    );

    final snapshot = await store.load();
    expect(
      snapshot.weakStatsByPriority.map((entry) => entry.key),
      <String>['older', 'newer', 'manual'],
    );
  });
}
