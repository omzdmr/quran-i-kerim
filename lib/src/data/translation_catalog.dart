const arabicOriginalSourceId = 'arabic_original';
const bundledTurkishTranslationId = 'turkish_rwwad';

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

  /// The catalog entry has been verified and may be shown to users.
  final bool available;

  /// A verified offline pack exists in our distribution pipeline.
  /// Candidate translations stay false until checksum/build validation exists.
  final bool downloadable;
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
    available: true,
    downloadable: false,
  ),
  TranslationInfo(
    id: 'english_rwwad',
    code: 'RWD-EN',
    languageCode: 'en',
    name: 'English Translation',
    publisher: 'Rowwad Translation Center',
    source: 'QuranEnc.com',
    sourceKey: 'english_rwwad',
    version: '1.0.19',
    bundled: false,
    available: true,
    downloadable: false,
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
    downloadable: false,
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
    downloadable: false,
  ),
];

TranslationInfo? translationById(String id) {
  for (final translation in translationCatalog) {
    if (translation.id == id) return translation;
  }
  return null;
}
