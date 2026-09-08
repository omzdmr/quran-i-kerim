const arabicOriginalSourceId = 'arabic_original';
const bundledTurkishTranslationId = 'turkish_rwwad';
const englishTranslationId = 'english_rwwad';

class TranslationInfo {
  const TranslationInfo({
    required this.id,
    required this.code,
    required this.languageCode,
    required this.name,
    required this.publisher,
    required this.source,
    required this.sourceKey,
    required this.version,
    required this.bundled,
    required this.available,
    required this.downloadable,
    this.assetPath,
    this.hasAudio = false,
  });

  final String id;
  final String code;
  final String languageCode;
  final String name;
  final String publisher;
  final String source;

  /// Upstream QuranEnc translation key. Kept separate from our internal ID so
  /// the package format can change without losing source provenance.
  final String sourceKey;

  final String version;

  /// Included in the application package and usable with no download.
  final bool bundled;

  /// Asset path for bundled translations. Arabic original is handled by the
  /// Quran text package and therefore has no TranslationInfo entry.
  final String? assetPath;

  /// The catalog entry has been verified and may be shown to users.
  final bool available;

  /// A verified network-download path exists and the app may install the pack.
  final bool downloadable;

  /// True only when this exact translation has a verified spoken-translation
  /// audio source. Arabic recitation is deliberately not treated as translation
  /// audio, so the reader never shows a misleading speaker icon.
  final bool hasAudio;
}

const translationCatalog = <TranslationInfo>[
  TranslationInfo(
    id: bundledTurkishTranslationId,
    code: 'RWD',
    languageCode: 'tr',
    name: 'Türkçe Tercüme',
    publisher: 'Rowad Tercüme Merkezi',
    source: 'QuranEnc.com',
    sourceKey: 'turkish_rwwad',
    version: '1.0.4',
    bundled: true,
    assetPath: 'assets/data/translations/tr_rwwad.json.gz',
    available: true,
    downloadable: false,
    hasAudio: false,
  ),
  TranslationInfo(
    id: englishTranslationId,
    code: 'RWD-EN',
    languageCode: 'en',
    name: 'English Translation',
    publisher: 'Rowwad Translation Center',
    source: 'QuranEnc.com',
    sourceKey: 'english_rwwad',
    version: '1.0.19',
    bundled: true,
    assetPath: 'assets/data/translations/en_rwwad.json.gz',
    available: true,
    downloadable: false,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'azeri_musayev',
    code: 'MUS-AZ',
    languageCode: 'az',
    name: 'Azərbaycan dilinə tərcümə',
    publisher: 'Əlixan Musayev · Rowwad Translation Center supervision',
    source: 'QuranEnc.com',
    sourceKey: 'azeri_musayev',
    version: '1.0.4',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: false,
  ),
  TranslationInfo(
    id: 'russian_rwwad',
    code: 'RWD-RU',
    languageCode: 'ru',
    name: 'Русский перевод',
    publisher: 'Rowwad Translation Center',
    source: 'QuranEnc.com',
    sourceKey: 'russian_rwwad',
    version: '1.0.1',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: false,
  ),
];

TranslationInfo? translationById(String id) {
  for (final translation in translationCatalog) {
    if (translation.id == id) return translation;
  }
  return null;
}

/// Default reading source for a fresh/device-language based setup.
///
/// Only sources guaranteed to exist offline are returned here. As more bundled
/// defaults are added, this mapping can grow without coupling UI language to
/// a specific translation forever.
String defaultQuranSourceForLanguage(String languageCode) {
  return switch (languageCode.toLowerCase()) {
    'ar' => arabicOriginalSourceId,
    'en' => englishTranslationId,
    'tr' => bundledTurkishTranslationId,
    _ => englishTranslationId,
  };
}
