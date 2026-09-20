import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('practice contexts persist locally newest first', () async {
    const store = MemorizationPracticeHistoryStore();
    final first = DateTime(2026, 9, 15, 8);
    final second = DateTime(2026, 9, 15, 9);

    await store.record(
      page: 42,
      context: MemorizationPracticeContext.soloReview,
      now: first,
    );
    await store.record(
      page: 42,
      context: MemorizationPracticeContext.prayer,
      now: second,
    );

    final restored = await store.load();

    expect(restored.events, hasLength(2));
    expect(restored.events.first.context, MemorizationPracticeContext.prayer);
    expect(restored.events.first.occurredAt, second);
    expect(restored.events.last.context, MemorizationPracticeContext.soloReview);
  });

  test('page counters can be filtered by practice context', () async {
    const store = MemorizationPracticeHistoryStore();

    await store.record(
      page: 12,
      context: MemorizationPracticeContext.recitedToSomeone,
      now: DateTime(2026, 9, 15, 8),
    );
    await store.record(
      page: 12,
      context: MemorizationPracticeContext.recitedToSomeone,
      now: DateTime(2026, 9, 15, 9),
    );
    await store.record(
      page: 12,
      context: MemorizationPracticeContext.soloReview,
      now: DateTime(2026, 9, 15, 10),
    );

    final snapshot = await store.load();

    expect(snapshot.countForPage(12), 3);
    expect(
      snapshot.countForPage(
        12,
        context: MemorizationPracticeContext.recitedToSomeone,
      ),
      2,
    );
    expect(snapshot.latestForPage(12)?.context, MemorizationPracticeContext.soloReview);
  });

  test('invalid Mushaf pages are ignored', () async {
    const store = MemorizationPracticeHistoryStore();

    await store.record(
      page: 0,
      context: MemorizationPracticeContext.prayer,
    );
    await store.record(
      page: 605,
      context: MemorizationPracticeContext.prayer,
    );

    expect((await store.load()).events, isEmpty);
  });

  test('corrupted persisted events are skipped instead of inventing history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1':
          '[{"id":"bad","page":999,"context":"prayer","occurredAt":"2026-09-15T08:00:00.000"},'
          '{"id":"ok","page":1,"context":"soloReview","occurredAt":"2026-09-15T09:00:00.000"}]',
    });
    const store = MemorizationPracticeHistoryStore();

    final snapshot = await store.load();

    expect(snapshot.events, hasLength(1));
    expect(snapshot.events.single.id, 'ok');
    expect(snapshot.events.single.page, 1);
  });

  test('a practice event can be deleted locally', () async {
    const store = MemorizationPracticeHistoryStore();

    final recorded = await store.record(
      page: 77,
      context: MemorizationPracticeContext.prayer,
      now: DateTime(2026, 9, 15, 11),
    );
    final eventId = recorded.events.single.id;

    final afterDelete = await store.remove(eventId);

    expect(afterDelete.events, isEmpty);
    expect((await store.load()).events, isEmpty);
  });
}
