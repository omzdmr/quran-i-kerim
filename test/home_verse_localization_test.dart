import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_verse_strings.dart';

void main() {
  test('home verse localization keeps TR EN AR AZ RU key parity', () {
    const locales = <String>['tr', 'en', 'ar', 'az', 'ru'];
    final expectedKeys = homeVerseStrings['tr']!.keys.toSet();

    expect(homeVerseStrings.keys.toSet(), locales.toSet());
    for (final locale in locales) {
      expect(
        homeVerseStrings[locale]!.keys.toSet(),
        expectedKeys,
        reason: 'Missing or extra home verse localization key for $locale',
      );
      expect(
        homeVerseStrings[locale]!.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Empty home verse localization value for $locale',
      );
    }
  });
}
