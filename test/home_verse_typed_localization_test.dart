import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_verse_strings.dart';

void main() {
  test('typed home verse getters resolve centralized copy for every locale', () {
    for (final locale in const <String>['tr', 'en', 'ar', 'az', 'ru']) {
      final l10n = AppLocalizations(Locale(locale));
      final expected = homeVerseStrings[locale]!;

      expect(l10n.homeVerseExpand, expected['homeVerseExpand']);
      expect(l10n.homeVerseCollapse, expected['homeVerseCollapse']);
      expect(l10n.homeVerseReadSurah, expected['homeVerseReadSurah']);
    }
  });
}
