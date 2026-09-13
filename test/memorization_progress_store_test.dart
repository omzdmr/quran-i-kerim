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
}
