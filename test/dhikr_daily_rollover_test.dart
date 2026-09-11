import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_daily_rollover.dart';

void main() {
  test('keeps daily counts when stored date is today', () {
    final original = <String, int>{'subhanallah': 12};

    final snapshot = normalizeDhikrDailySnapshot(
      storedDateKey: '2026-09-11',
      todayDateKey: '2026-09-11',
      counts: original,
    );

    expect(snapshot.dateKey, '2026-09-11');
    expect(snapshot.counts, {'subhanallah': 12});
    expect(identical(snapshot.counts, original), isFalse);
  });

  test('clears stale daily counts when the calendar day changes', () {
    final snapshot = normalizeDhikrDailySnapshot(
      storedDateKey: '2026-09-10',
      todayDateKey: '2026-09-11',
      counts: {'subhanallah': 12, 'alhamdulillah': 7},
    );

    expect(snapshot.dateKey, '2026-09-11');
    expect(snapshot.counts, isEmpty);
  });

  test('treats a missing stored date as a fresh day', () {
    final snapshot = normalizeDhikrDailySnapshot(
      storedDateKey: null,
      todayDateKey: '2026-09-11',
      counts: {'subhanallah': 12},
    );

    expect(snapshot.dateKey, '2026-09-11');
    expect(snapshot.counts, isEmpty);
  });
}
