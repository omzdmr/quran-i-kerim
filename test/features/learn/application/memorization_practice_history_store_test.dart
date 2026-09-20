import 'dart:convert';

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

  test('load ignores malformed, invalid-page, and unknown-context events', () async {
    final validTime = DateTime.utc(2026, 9, 15, 12);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': jsonEncode(<Object>[
        <String, Object>{
          'id': 'valid',
          'page': 12,
          'context': MemorizationPracticeContext.prayer.name,
          'occurredAt': validTime.toIso8601String(),
        },
        <String, Object>{
          'id': 'invalid-page',
          'page': 605,
          'context': MemorizationPracticeContext.soloReview.name,
          'occurredAt': validTime.toIso8601String(),
        },
        <String, Object>{
          'id': 'unknown-context',
          'page': 13,
          'context': 'automaticSpeechScore',
          'occurredAt': validTime.toIso8601String(),
        },
        <String, Object>{
          'id': 'bad-date',
          'page': 14,
          'context': MemorizationPracticeContext.recitedToSomeone.name,
          'occurredAt': 'not-a-date',
        },
      ]),
    });

    final snapshot = await const MemorizationPracticeHistoryStore().load();

    expect(snapshot.events, hasLength(1));
    expect(snapshot.events.single.id, 'valid');
    expect(snapshot.events.single.page, 12);
    expect(snapshot.events.single.context, MemorizationPracticeContext.prayer);
  });

  test('duplicate persisted event ids keep the last valid entry', () async {
    final earlier = DateTime.utc(2026, 9, 14, 8);
    final later = DateTime.utc(2026, 9, 15, 8);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': jsonEncode(<Object>[
        <String, Object>{
          'id': 'same-id',
          'page': 30,
          'context': MemorizationPracticeContext.soloReview.name,
          'occurredAt': earlier.toIso8601String(),
        },
        <String, Object>{
          'id': 'same-id',
          'page': 31,
          'context': MemorizationPracticeContext.recitedToSomeone.name,
          'occurredAt': later.toIso8601String(),
        },
      ]),
    });

    final snapshot = await const MemorizationPracticeHistoryStore().load();

    expect(snapshot.events, hasLength(1));
    expect(snapshot.events.single.page, 31);
    expect(
      snapshot.events.single.context,
      MemorizationPracticeContext.recitedToSomeone,
    );
    expect(snapshot.events.single.occurredAt, later);
  });

  test('load caps restored practice history at the newest 400 events', () async {
    final base = DateTime.utc(2026, 1, 1);
    final persisted = List<Object>.generate(405, (index) {
      return <String, Object>{
        'id': 'event-$index',
        'page': 12,
        'context': MemorizationPracticeContext.soloReview.name,
        'occurredAt': base.add(Duration(minutes: index)).toIso8601String(),
      };
    });
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_history_v1': jsonEncode(persisted),
    });

    final snapshot = await const MemorizationPracticeHistoryStore().load();

    expect(snapshot.events, hasLength(400));
    expect(snapshot.events.first.id, 'event-404');
    expect(snapshot.events.last.id, 'event-5');
  });
}
