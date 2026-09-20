import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/settings/reading_streak.dart';

void main() {
  group('calculateReadingStreak', () {
    final now = DateTime(2026, 9, 11, 14, 30);

    test('counts from today when today has reading activity', () {
      expect(
        calculateReadingStreak(
          {'2026-09-11', '2026-09-10', '2026-09-09'},
          now: now,
        ),
        3,
      );
    });

    test('keeps an active streak when today has not been read yet', () {
      expect(
        calculateReadingStreak(
          {'2026-09-10', '2026-09-09', '2026-09-08'},
          now: now,
        ),
        3,
      );
    });

    test('returns zero when neither today nor yesterday was read', () {
      expect(
        calculateReadingStreak({'2026-09-09', '2026-09-08'}, now: now),
        0,
      );
    });

    test('stops at the first missing day', () {
      expect(
        calculateReadingStreak(
          {'2026-09-11', '2026-09-10', '2026-09-08'},
          now: now,
        ),
        2,
      );
    });
  });
}
