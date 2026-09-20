import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_recent_reading_strings.dart';

void main() {
  test('Home recent-reading strings have parity in every locale', () {
    final expected = homeRecentReadingStrings['tr']!.keys.toSet();

    expect(
      homeRecentReadingStrings.keys,
      containsAll(<String>['tr', 'en', 'ar', 'az', 'ru']),
    );

    for (final entry in homeRecentReadingStrings.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });
}
