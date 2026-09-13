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

  test('empty question ids are ignored', () async {
    const store = MemorizationRecallHistoryStore();

    final snapshot = await store.recordResult('', known: false);

    expect(snapshot.stats, isEmpty);
  });
}
