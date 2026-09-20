import 'dart:ui';

enum LocaleScriptDirection { ltr, rtl }

class AppLocaleMetadata {
  const AppLocaleMetadata({
    required this.languageTag,
    required this.nativeName,
    required this.scriptCode,
    required this.direction,
    required this.humanReviewRequired,
  });

  /// Canonical BCP-47 language tag used by the UI locale.
  final String languageTag;
  final String nativeName;

  /// ISO 15924 script code for the primary UI script.
  final String scriptCode;
  final LocaleScriptDirection direction;

  /// True while production copy still requires human linguistic review.
  final bool humanReviewRequired;

  String get languageCode => languageTag.split('-').first.toLowerCase();
  bool get isRtl => direction == LocaleScriptDirection.rtl;
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
}

/// Canonical metadata for full application locales.
///
/// Quran meaning/audio languages are deliberately NOT inferred from this list.
/// Their availability is controlled independently by rights-cleared content
/// catalogs and manifests.
const appLocaleMetadata = <String, AppLocaleMetadata>{
  'tr': AppLocaleMetadata(
    languageTag: 'tr',
    nativeName: 'Türkçe',
    scriptCode: 'Latn',
    direction: LocaleScriptDirection.ltr,
    humanReviewRequired: false,
  ),
  'en': AppLocaleMetadata(
    languageTag: 'en',
    nativeName: 'English',
    scriptCode: 'Latn',
    direction: LocaleScriptDirection.ltr,
    humanReviewRequired: false,
  ),
  'ar': AppLocaleMetadata(
    languageTag: 'ar',
    nativeName: 'العربية',
    scriptCode: 'Arab',
    direction: LocaleScriptDirection.rtl,
    humanReviewRequired: false,
  ),
  'az': AppLocaleMetadata(
    languageTag: 'az',
    nativeName: 'Azərbaycanca',
    scriptCode: 'Latn',
    direction: LocaleScriptDirection.ltr,
    humanReviewRequired: false,
  ),
  'ru': AppLocaleMetadata(
    languageTag: 'ru',
    nativeName: 'Русский',
    scriptCode: 'Cyrl',
    direction: LocaleScriptDirection.ltr,
    humanReviewRequired: false,
  ),
  'fr': AppLocaleMetadata(
    languageTag: 'fr',
    nativeName: 'Français',
    scriptCode: 'Latn',
    direction: LocaleScriptDirection.ltr,
    humanReviewRequired: true,
  ),
};

AppLocaleMetadata? metadataForLocale(Locale locale) {
  return appLocaleMetadata[locale.languageCode.toLowerCase()];
}
