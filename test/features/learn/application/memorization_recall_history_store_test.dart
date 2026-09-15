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
}
