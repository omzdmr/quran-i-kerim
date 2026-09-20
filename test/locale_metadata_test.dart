import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/locale_metadata.dart';

void main() {
  test('locale metadata exactly matches supported UI locales', () {
    final supported = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    expect(appLocaleMetadata.keys.toSet(), supported);
  });

  test('metadata uses canonical native names, scripts and directions', () {
    expect(appLocaleMetadata['tr']!.scriptCode, 'Latn');
    expect(appLocaleMetadata['en']!.scriptCode, 'Latn');
    expect(appLocaleMetadata['az']!.scriptCode, 'Latn');
    expect(appLocaleMetadata['fr']!.scriptCode, 'Latn');
    expect(appLocaleMetadata['ru']!.scriptCode, 'Cyrl');
    expect(appLocaleMetadata['ar']!.scriptCode, 'Arab');

    expect(appLocaleMetadata['ar']!.textDirection, TextDirection.rtl);
    for (final code in const <String>['tr', 'en', 'az', 'ru', 'fr']) {
      expect(appLocaleMetadata[code]!.textDirection, TextDirection.ltr);
    }

    expect(appLocaleMetadata['fr']!.nativeName, 'Français');
    expect(appLocaleMetadata['ar']!.nativeName, 'العربية');
  });

  test('French draft remains explicitly gated by human review', () {
    expect(appLocaleMetadata['fr']!.humanReviewRequired, isTrue);
  });

  test('regional variants resolve metadata by language subtag', () {
    expect(metadataForLocale(const Locale('fr', 'CA'))?.languageTag, 'fr');
    expect(metadataForLocale(const Locale('ar', 'SA'))?.isRtl, isTrue);
    expect(metadataForLocale(const Locale('de', 'DE')), isNull);
  });
}
