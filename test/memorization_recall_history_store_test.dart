import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_recall_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a missed recall becomes weak and survives reload', () async {
    const store = MemorizationRecallHistoryStore();
    final attemptedAt = DateTime(2026, 9, 13, 18, 30);

    await store.recordResult('2:6', known: false, now: attemptedAt);
    final restored = await store.load();
    final stat = restored.statFor('2:6');

    expect(stat?.difficulty, 2);
    expect(stat?.attempts, 1);
    expect(stat?.lastAttemptAt, attemptedAt);
    expect(restored.weakQuestionIds, contains('2:6'));
  });

  test('successful recalls gradually clear a weak verse', () async {
    const store = MemorizationRecallHistoryStore();

    await store.recordResult('2:6', known: false);
    final firstRecovery = await store.recordResult('2:6', known: true);
    final recovered = await store.recordResult('2:6', known: true);

    expect(firstRecovery.statFor('2:6')?.difficulty, 1);
    expect(firstRecovery.weakQuestionIds, contains('2:6'));
    expect(recovered.statFor('2:6')?.difficulty, 0);
    expect(recovered.weakQuestionIds, isNot(contains('2:6')));
    expect(recovered.statFor('2:6')?.attempts, 3);
  });

  test('assisted recall is a moderate weak signal', () async {
    const store = MemorizationRecallHistoryStore();

    final assisted = await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.assisted,
      now: DateTime(2026, 9, 13, 19),
    );
    final missed = await store.recordAssessment(
      '2:7',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime(2026, 9, 13, 19),
    );

    expect(assisted.statFor('2:6')?.difficulty, 1);
    expect(assisted.statFor('2:6')?.attempts, 1);
    expect(assisted.weakQuestionIds, contains('2:6'));
    expect(missed.statFor('2:7')?.difficulty, 2);

    final recovered = await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.independent,
    );
    expect(recovered.statFor('2:6')?.difficulty, 0);
    expect(recovered.weakQuestionIds, isNot(contains('2:6')));
  });

  test('weak verses are ordered by difficulty then oldest attempt', () async {
    const store = MemorizationRecallHistoryStore();

    await store.recordResult(
      '2:7',
      known: false,
      now: DateTime(2026, 9, 13, 12),
    );
    await store.recordResult(
      '2:6',
      known: false,
      now: DateTime(2026, 9, 13, 13),
    );
    await store.recordResult(
      '2:6',
      known: false,
      now: DateTime(2026, 9, 13, 14),
    );
    await store.recordResult(
      '2:8',
      known: false,
      now: DateTime(2026, 9, 13, 11),
    );

    final snapshot = await store.load();

    expect(
      snapshot.weakStatsByPriority.map((entry) => entry.key),
      orderedEquals(<String>['2:6', '2:8', '2:7']),
    );
  });

  test('a manually confusing verse becomes weak without a fake attempt', () async {
    const store = MemorizationRecallHistoryStore();

    await store.setManuallyWeak('2:6', weak: true);
    final restored = await store.load();
    final stat = restored.statFor('2:6');

    expect(stat?.manuallyWeak, isTrue);
    expect(stat?.difficulty, 0);
    expect(stat?.priorityDifficulty, 1);
    expect(stat?.attempts, 0);
    expect(stat?.lastAttemptAt, isNull);
    expect(restored.manuallyWeakQuestionIds, contains('2:6'));
    expect(restored.weakQuestionIds, contains('2:6'));
  });

  test('clearing a manual weak flag keeps test-derived difficulty intact', () async {
    const store = MemorizationRecallHistoryStore();

    await store.recordAssessment(
      '2:6',
      assessment: MemorizationRecallAssessment.struggled,
      now: DateTime(2026, 9, 13, 19),
    );
    await store.setManuallyWeak('2:6', weak: true);
    final cleared = await store.setManuallyWeak('2:6', weak: false);

    expect(cleared.statFor('2:6')?.manuallyWeak, isFalse);
    expect(cleared.statFor('2:6')?.difficulty, 2);
    expect(cleared.weakQuestionIds, contains('2:6'));
  });

  test('clearing a manual-only weak flag removes the synthetic entry', () async {
    const store = MemorizationRecallHistoryStore();

    await store.setManuallyWeak('2:6', weak: true);
    final cleared = await store.setManuallyWeak('2:6', weak: false);

    expect(cleared.statFor('2:6'), isNull);
    expect(cleared.weakQuestionIds, isNot(contains('2:6')));
  });

  test('empty question ids are ignored', () async {
    const store = MemorizationRecallHistoryStore();

    final snapshot = await store.recordResult('', known: false);

    expect(snapshot.stats, isEmpty);
  });
}
