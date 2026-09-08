const arabicOriginalSourceId = 'arabic_original';
const bundledTurkishTranslationId = 'turkish_rwwad';
const englishTranslationId = 'english_rwwad';
const turkishShabanTranslationId = 'turkish_shaban';
const turkishAliOzekTranslationId = 'turkish_shahin';
const turkishVakfiTranslationId = 'turkish_vakfi';

enum TranslationProvider { quranEnc, islamicNetwork }

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
    this.provider = TranslationProvider.quranEnc,
  });

  final String id;
  final String code;
  final String languageCode;
  final String name;
  final String publisher;
  final String source;
  final String sourceKey;
  final String version;
  final bool bundled;
  final String? assetPath;
  final bool available;
  final bool downloadable;
  final bool hasAudio;
  final TranslationProvider provider;
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
  ),
  TranslationInfo(
    id: turkishShabanTranslationId,
    code: 'ŞP-TR',
    languageCode: 'tr',
    name: 'Türkçe Tercüme - Şaban Piriş',
    publisher: 'Şaban Piriş · Rowad Tercüme Merkezi gözetimi',
    source: 'QuranEnc.com',
    sourceKey: 'turkish_shaban',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
  ),
  TranslationInfo(
    id: turkishAliOzekTranslationId,
    code: 'AÖ-TR',
    languageCode: 'tr',
    name: 'Türkçe Tercüme - Dr. Ali Özek ve Diğerleri',
    publisher: 'Dr. Ali Özek ve Diğerleri · Rowad Tercüme Merkezi gözetimi',
    source: 'QuranEnc.com',
    sourceKey: 'turkish_shahin',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
  ),
  TranslationInfo(
    id: turkishVakfiTranslationId,
    code: 'VAKFI-TR',
    languageCode: 'tr',
    name: 'Diyanet Vakfı Meali',
    publisher: 'Diyanet Vakfı',
    source: 'Al Quran Cloud · Islamic Network',
    sourceKey: 'tr.vakfi',
    version: 'provider-current',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
    provider: TranslationProvider.islamicNetwork,
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
    id: 'french_rashid',
    code: 'RSH-FR',
    languageCode: 'fr',
    name: 'Traduction française',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'french_rashid',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'portuguese_nasr',
    code: 'NASR-PT',
    languageCode: 'pt',
    name: 'Tradução portuguesa',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'portuguese_nasr',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'dutch_center',
    code: 'CTR-NL',
    languageCode: 'nl',
    name: 'Nederlandse vertaling',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'dutch_center',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'tagalog_rwwad',
    code: 'RWD-TL',
    languageCode: 'tl',
    name: 'Salin sa Tagalog',
    publisher: 'Rowwad Translation Center',
    source: 'QuranEnc.com',
    sourceKey: 'tagalog_rwwad',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'chinese_suliman',
    code: 'SLM-ZH',
    languageCode: 'zh',
    name: '中文翻译',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'chinese_suliman',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'vietnamese_rwwad',
    code: 'RWD-VI',
    languageCode: 'vi',
    name: 'Bản dịch tiếng Việt',
    publisher: 'Rowwad Translation Center',
    source: 'QuranEnc.com',
    sourceKey: 'vietnamese_rwwad',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'persian_ih',
    code: 'IH-FA',
    languageCode: 'fa',
    name: 'ترجمه فارسی',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'persian_ih',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'assamese_rafeeq',
    code: 'RAF-AS',
    languageCode: 'as',
    name: 'অসমীয়া অনুবাদ',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'assamese_rafeeq',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'sinhalese_mahir',
    code: 'MHR-SI',
    languageCode: 'si',
    name: 'සිංහල පරිවර්තනය',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'sinhalese_mahir',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
  TranslationInfo(
    id: 'somali_yacob',
    code: 'YCB-SO',
    languageCode: 'so',
    name: 'Tarjumaadda Soomaaliga',
    publisher: 'QuranEnc.com',
    source: 'QuranEnc.com',
    sourceKey: 'somali_yacob',
    version: 'latest',
    bundled: false,
    available: true,
    downloadable: true,
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
  ),
];

TranslationInfo? translationById(String id) {
  for (final translation in translationCatalog) {
    if (translation.id == id) return translation;
  }
  return null;
}

String defaultQuranSourceForLanguage(String languageCode) {
  return switch (languageCode.toLowerCase()) {
    'ar' => arabicOriginalSourceId,
    'en' => englishTranslationId,
    'tr' => bundledTurkishTranslationId,
    _ => englishTranslationId,
  };
}
