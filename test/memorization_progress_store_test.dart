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

  test('toggling a memorized page removes it without deleting practice day', () async {
    const store = MemorizationProgressStore();
    await store.togglePage(1, now: DateTime(2026, 9, 13));
    final removed = await store.togglePage(1, now: DateTime(2026, 9, 13));

    expect(removed.containsPage(1), isFalse);
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
