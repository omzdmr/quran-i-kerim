class TranslationInfo {
  const TranslationInfo({
    required this.id,
    required this.code,
    required this.languageCode,
    required this.name,
    required this.publisher,
    required this.source,
    required this.version,
    required this.bundled,
    required this.available,
  });

  final String id;
  final String code;
  final String languageCode;
  final String name;
  final String publisher;
  final String source;
  final String version;
  final bool bundled;
  final bool available;
}

const translationCatalog = <TranslationInfo>[
  TranslationInfo(
    id: 'turkish_rwwad',
    code: 'RWD',
    languageCode: 'tr',
    name: 'Türkçe Tercüme',
    publisher: 'Rowad Tercüme Merkezi',
    source: 'QuranEnc.com',
    version: '1.0.4',
    bundled: true,
    available: false,
  ),
];
