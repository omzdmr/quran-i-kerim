import 'locale_metadata.dart';

/// Machine-readable localization QA summary for one full-app UI locale.
///
/// This intentionally measures UI localization only. Quran meaning/audio/font
/// pack availability belongs to the separately licensed content catalog.
class LocaleCoverage {
  const LocaleCoverage({
    required this.languageCode,
    required this.translatedKeys,
    required this.totalKeys,
    required this.humanReviewRequired,
  });

  final String languageCode;
  final int translatedKeys;
  final int totalKeys;
  final bool humanReviewRequired;

  double get ratio => totalKeys == 0 ? 0 : translatedKeys / totalKeys;

  bool get hasFullKeyCoverage => totalKeys > 0 && translatedKeys == totalKeys;

  bool get releaseReady => hasFullKeyCoverage && !humanReviewRequired;
}

/// Builds deterministic UI-locale coverage from localization maps.
///
/// [referenceLanguageCode] defines the expected key set. A key counts as
/// translated only when it exists and contains non-whitespace text. Extra keys
/// do not inflate coverage. Human-review state comes from [appLocaleMetadata],
/// keeping review policy independent from raw key parity.
List<LocaleCoverage> buildLocaleCoverage(
  Map<String, Map<String, String>> localizedValues, {
  String referenceLanguageCode = 'en',
}) {
  final reference = localizedValues[referenceLanguageCode];
  if (reference == null) {
    throw ArgumentError.value(
      referenceLanguageCode,
      'referenceLanguageCode',
      'reference locale is missing',
    );
  }

  final expectedKeys = reference.keys.toSet();
  return appLocaleMetadata.map((metadata) {
    final values = localizedValues[metadata.languageCode] ?? const <String, String>{};
    final translated = expectedKeys.where((key) {
      final value = values[key];
      return value != null && value.trim().isNotEmpty;
    }).length;

    return LocaleCoverage(
      languageCode: metadata.languageCode,
      translatedKeys: translated,
      totalKeys: expectedKeys.length,
      humanReviewRequired: metadata.humanReviewRequired,
    );
  }).toList(growable: false);
}
