import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_prayer_strings.dart';

void main() {
  const locales = ['tr', 'en', 'ar', 'az', 'ru'];
  const expectedKeys = {
    'homePrayerHourShort',
    'homePrayerMinuteShort',
  };

  test('home prayer duration strings keep locale key parity', () {
    expect(homePrayerStrings.keys.toSet(), locales.toSet());
    for (final locale in locales) {
      expect(homePrayerStrings[locale]!.keys.toSet(), expectedKeys);
    }
  });

  test('home prayer duration units resolve through AppLocalizations', () {
    const expected = {
      'tr': ('sa', 'dk'),
      'en': ('h', 'm'),
      'ar': ('س', 'د'),
      'az': ('s', 'dəq'),
      'ru': ('ч', 'мин'),
    };

    for (final entry in expected.entries) {
      final l10n = AppLocalizations(Locale(entry.key));
      expect(l10n.homePrayerHourShort, entry.value.$1);
      expect(l10n.homePrayerMinuteShort, entry.value.$2);
    }
  });

  test('home prayer remaining label uses generated localization', () {
    final source = File(
      'lib/src/features/home/home_prayer_card.dart',
    ).readAsStringSync();

    expect(source, contains('generatedL10n.remaining'));
    expect(source, isNot(contains("l10n.text('remaining')")));
  });
}
