import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('memorization pages stay local and next page advances', () async {
    const store = MemorizationProgressStore();
    final first = await store.togglePage(1, now: DateTime(2026, 9, 13));
    final second = await store.togglePage(2, now: DateTime(2026, 9, 13));
    final restored = await store.load();

    expect(first.containsPage(1), isTrue);
    expect(second.memorizedCount, 2);
    expect(restored.memorizedPages, {1, 2});
    expect(restored.nextPage, 3);
    expect(restored.practiceDays, contains('2026-09-13'));
  });

  test('memorizedAt metadata survives a local reload', () async {
    const store = MemorizationProgressStore();
    final memorizedAt = DateTime(2026, 9, 13, 8, 30);

    await store.togglePage(12, now: memorizedAt);
    final restored = await store.load();

    expect(restored.progressForPage(12)?.memorizedAt, memorizedAt);
    expect(restored.progressForPage(12)?.lastReviewedAt, isNull);
    expect(restored.progressForPage(12)?.selfAssessment, isNull);
  });

  test('new memorization assessment does not mark the page reviewed', () async {
    const store = MemorizationProgressStore();
    final memorizedAt = DateTime(2026, 9, 13, 8, 30);
    final assessedAt = DateTime(2026, 9, 13, 9, 15);

    await store.togglePage(12, now: memorizedAt);
    await store.recordSelfAssessment(
      12,
      selfAssessment: MemorizationSelfAssessment.assisted,
      now: assessedAt,
    );
    final restored = await store.load();
    final progress = restored.progressForPage(12);

    expect(progress?.memorizedAt, memorizedAt);
    expect(progress?.lastReviewedAt, isNull);
    expect(progress?.selfAssessment, MemorizationSelfAssessment.assisted);
    expect(restored.practiceDays, contains('2026-09-13'));
  });

  test('review metadata and self assessment survive a local reload', () async {
    const store = MemorizationProgressStore();
    final memorizedAt = DateTime(2026, 9, 10, 9);
    final reviewedAt = DateTime(2026, 9, 13, 18, 45);

    await store.togglePage(12, now: memorizedAt);
    await store.recordReview(
      12,
      selfAssessment: MemorizationSelfAssessment.independent,
      now: reviewedAt,
    );
    final restored = await store.load();
    final progress = restored.progressForPage(12);

    expect(progress?.memorizedAt, memorizedAt);
    expect(progress?.lastReviewedAt, reviewedAt);
    expect(
      progress?.selfAssessment,
      MemorizationSelfAssessment.independent,
    );
    expect(restored.practiceDays, contains('2026-09-13'));
  });

  test('review metadata is ignored for pages not marked memorized', () async {
    const store = MemorizationProgressStore();

    final snapshot = await store.recordReview(
      12,
      selfAssessment: MemorizationSelfAssessment.assisted,
      now: DateTime(2026, 9, 13),
    );

    expect(snapshot.progressForPage(12), isNull);
    expect(snapshot.practiceDays, isEmpty);
  });

  test('toggling a memorized page removes it without deleting practice day', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(1, now: DateTime(2026, 9, 13));
    final removed = await store.togglePage(1, now: DateTime(2026, 9, 13));

    expect(removed.containsPage(1), isFalse);
    expect(removed.progressForPage(1), isNull);
    expect(removed.nextPage, 1);
    expect(removed.practiceDays, contains('2026-09-13'));
  });

  test('invalid page numbers are ignored', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(0);
    await store.togglePage(605);
    final restored = await store.load();

    expect(restored.memorizedPages, isEmpty);
    expect(restored.practiceDays, isEmpty);
  });

  test('load normalizes invalid memorized page keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['12', 'bad', '0', '605', '2', '12'],
    });
    const store = MemorizationProgressStore();

    final restored = await store.load();
    final prefs = await SharedPreferences.getInstance();

    expect(restored.memorizedPages, <int>{2, 12});
    expect(
      prefs.getStringList('memorized_pages_v1'),
      <String>['2', '12'],
    );
  });

  test('load normalizes invalid practice day keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_practice_days_v1': <String>[
        '2026-09-14',
        'bad',
        '2026-02-31',
        '2026-09-13',
        '2026-09-14',
      ],
    });
    const store = MemorizationProgressStore();

    final restored = await store.load();
    final prefs = await SharedPreferences.getInstance();

    expect(restored.practiceDays, <String>{'2026-09-13', '2026-09-14'});
    expect(
      prefs.getStringList('memorization_practice_days_v1'),
      <String>['2026-09-13', '2026-09-14'],
    );
  });

  test('load normalizes invalid and orphan page progress metadata', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['12'],
      'memorization_page_progress_v1':
          '{"12":{"memorizedAt":"2026-09-13T08:30:00.000Z","lastReviewedAt":"bad","selfAssessment":"bogus"},"99":{"memorizedAt":"2026-09-01T00:00:00.000Z"},"605":{"memorizedAt":"2026-09-01T00:00:00.000Z"},"bad":{}}',
    });
    const store = MemorizationProgressStore();

    final restored = await store.load();
    final prefs = await SharedPreferences.getInstance();

    expect(restored.pageProgress.keys, <int>[12]);
    expect(restored.progressForPage(12)?.memorizedAt, DateTime.utc(2026, 9, 13, 8, 30));
    expect(restored.progressForPage(12)?.lastReviewedAt, isNull);
    expect(restored.progressForPage(12)?.selfAssessment, isNull);
    expect(
      prefs.getString('memorization_page_progress_v1'),
      '{"12":{"memorizedAt":"2026-09-13T08:30:00.000Z","lastReviewedAt":null,"selfAssessment":null}}',
    );
  });
}
