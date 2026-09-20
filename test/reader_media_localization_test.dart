import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_media_strings.dart';

void main() {
  test('reader media copy keeps locale key parity', () {
    final expected = readerMediaStrings['en']!.keys.toSet();

    for (final locale in const ['tr', 'en', 'ar', 'az', 'ru', 'fr']) {
      expect(readerMediaStrings[locale]!.keys.toSet(), expected);
    }
  });

  test('reader media metadata resolves through app localization', () {
    final ru = AppLocalizations(const Locale('ru'));

    expect(ru.readerMediaChannel, 'Аудио Корана');
    expect(ru.readerMediaTitle(2, 255), 'Коран 2:255');
    expect(
      ru.readerMediaArtist('Мишари Рашид', 255, 286),
      'Мишари Рашид · Аят 255/286',
    );
  });

  test('reader media copy is available in all supported locales', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final copy = AppLocalizations(locale);
      expect(copy.readerMediaChannel, isNotEmpty);
      expect(copy.readerMediaTitle(1, 1), isNotEmpty);
      expect(copy.readerMediaArtist('Source', 1, 7), contains('1/7'));
    }
  });
}
