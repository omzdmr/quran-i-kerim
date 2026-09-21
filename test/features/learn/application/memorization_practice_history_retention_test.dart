import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = MemorizationPracticeHistoryStore();

  test('history is no longer truncated at the old 400-event ceiling', () async {
    SharedPreferences.setMockInitialValues({});
    final base = DateTime(2026, 1, 1);
    for (var index = 0; index < 405; index++) {
      await store.record(
        page: 1 + (index % 20),
        context: MemorizationPracticeContext.soloReview,
        now: base.add(Duration(minutes: index)),
      );
    }

    final history = await store.load();
    expect(history.events.length, 405);
    expect(history.events.first.occurredAt, base.add(const Duration(minutes: 404)));
    expect(history.events.last.occurredAt, base);
  });

  test('public retention ceiling remains bounded', () {
    expect(MemorizationPracticeHistoryStore.maxEvents, 4000);
  });
}
