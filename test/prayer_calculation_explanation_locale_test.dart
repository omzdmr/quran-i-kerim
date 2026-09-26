import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  const locales = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
  const keys = <String>[
    'calculationMethod',
    'method',
    'automatic',
    'asrCalculation',
    'hanafi',
    'standard',
    'highLatitude',
    'recommended',
    'middleOfNight',
    'seventhOfNight',
    'twilightAngle',
    'minuteAdjustments',
    'minuteUnit',
    'prayerOfflineInfo',
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  for (final locale in locales) {
    test('$locale exposes every string used by prayer calculation explanation', () {
      final l10n = AppLocalizations(Locale(locale));
      for (final key in keys) {
        final value = l10n.text(key);
        expect(value.trim(), isNotEmpty, reason: '$locale:$key is empty');
        expect(value, isNot(key), reason: '$locale:$key fell back to raw key');
      }
    });
  }
}
