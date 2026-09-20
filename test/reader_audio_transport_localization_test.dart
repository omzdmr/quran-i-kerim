import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_audio_transport_strings.dart';

void main() {
  const locales = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
  const requiredKeys = <String>{
    'readerAudioPlay',
    'readerAudioPause',
    'readerAudioPreviousVerse',
    'readerAudioNextVerse',
  };

  test('reader audio transport copy keeps core-locale key parity', () {
    for (final locale in locales) {
      final values = readerAudioTransportStrings[locale];
      expect(
        values,
        isNotNull,
        reason: 'Missing reader audio transport locale $locale',
      );
      expect(
        values!.keys.toSet(),
        requiredKeys,
        reason: 'Reader audio transport key drift for $locale',
      );
      for (final key in requiredKeys) {
        expect(values[key]!.trim(), isNotEmpty, reason: '$locale:$key is empty');
      }
    }
  });

  test('reader audio transport copy resolves through AppLocalizations', () {
    expect(AppLocalizations(const Locale('tr')).readerAudioPlay, 'Oynat');
    expect(AppLocalizations(const Locale('en')).readerAudioPause, 'Pause');
    expect(
      AppLocalizations(const Locale('ar')).readerAudioPreviousVerse,
      'الآية السابقة',
    );
    expect(
      AppLocalizations(const Locale('az')).readerAudioNextVerse,
      'Növbəti ayə',
    );
    expect(
      AppLocalizations(const Locale('ru')).readerAudioPlay,
      'Воспроизвести',
    );
    expect(AppLocalizations(const Locale('fr')).readerAudioPlay, 'Lire');
  });
}
