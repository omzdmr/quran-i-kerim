import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('record persists real-world practice in newest-first order', () async {
    const store = MemorizationPracticeHistoryStore();
    final earlier = DateTime.utc(2026, 9, 14, 8);
    final later = DateTime.utc(2026, 9, 15, 9);

    await store.record(
      page: 12,
      context: MemorizationPracticeContext.soloReview,
      now: earlier,
    );
    final snapshot = await store.record(
      page: 12,
      context: MemorizationPracticeContext.prayer,
      now: later,
    );

    expect(snapshot.eventsForPage(12), hasLength(2));
    expect(snapshot.eventsForPage(12).first.context,
        MemorizationPracticeContext.prayer);
    expect(snapshot.latestForPage(12)?.occurredAt, later);
    expect(snapshot.countForPage(12), 2);
    expect(
      snapshot.countForPage(
        12,
        context: MemorizationPracticeContext.soloReview,
      ),
      1,
    );

    final reloaded = await store.load();
    expect(reloaded.eventsForPage(12), hasLength(2));
    expect(reloaded.eventsForPage(12).first.occurredAt, later);
  });

  test('remove deletes only the selected practice event', () async {
    const store = MemorizationPracticeHistoryStore();

    final first = await store.record(
      page: 20,
      context: MemorizationPracticeContext.recitedToSomeone,
      now: DateTime.utc(2026, 9, 14, 10),
    );
    final firstId = first.events.single.id;
    await store.record(
      page: 21,
      context: MemorizationPracticeContext.soloReview,
      now: DateTime.utc(2026, 9, 15, 10),
    );

    final updated = await store.remove(firstId);

    expect(updated.eventsForPage(20), isEmpty);
    expect(updated.eventsForPage(21), hasLength(1));
    expect((await store.load()).eventsForPage(20), isEmpty);
  });
}
