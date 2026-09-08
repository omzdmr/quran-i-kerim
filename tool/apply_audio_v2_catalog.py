from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


# ---------------------------------------------------------------------------
# Audio catalog: many Arabic reciters + every QuranEnc spoken translation +
# Turkish Vakfi audio. No TTS.
# ---------------------------------------------------------------------------
Path('lib/src/data/quran_audio_catalog.dart').write_text(r'''import 'translation_catalog.dart';

enum QuranAudioKind { recitation, translation }

enum QuranAudioProvider { quranEnc, islamicNetwork }

class QuranAudioInfo {
  const QuranAudioInfo({
    required this.id,
    required this.sourceId,
    required this.languageCode,
    required this.code,
    required this.title,
    required this.attribution,
    required this.kind,
    required this.provider,
    required this.providerKey,
    this.bitrate,
    this.style,
  });

  final String id;
  final String sourceId;
  final String languageCode;
  final String code;
  final String title;
  final String attribution;
  final QuranAudioKind kind;
  final QuranAudioProvider provider;
  final String providerKey;
  final int? bitrate;
  final String? style;
}

const quranAudioCatalog = <QuranAudioInfo>[
  QuranAudioInfo(
    id: 'arabic_recitation_alafasy',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mishary Rashid Alafasy',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.alafasy',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_husary',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mahmoud Khalil Al-Husary',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.husary',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_minshawi',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mohamed Siddiq Al-Minshawi',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.minshawi',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_minshawi_mujawwad',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mohamed Siddiq Al-Minshawi',
    attribution: 'Islamic Network · Al Quran Cloud · 64 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.minshawimujawwad',
    bitrate: 64,
    style: 'Mujawwad',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_sudais',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abdul Rahman Al-Sudais',
    attribution: 'Islamic Network · Al Quran Cloud · 192 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.sudais',
    bitrate: 192,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_shuraim',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Saud Al-Shuraim',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.shuraim',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_abdulbasit',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abdul Basit Abdul Samad',
    attribution: 'Islamic Network · Al Quran Cloud · 192 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.abdulbasit',
    bitrate: 192,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_abdulbasit_mujawwad',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abdul Basit Abdul Samad',
    attribution: 'Islamic Network · Al Quran Cloud · 192 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.abdulbasitmujawwad',
    bitrate: 192,
    style: 'Mujawwad',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_ajamy',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Ahmed ibn Ali Al-Ajamy',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.ajamy',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_muhammad_ayyoub',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Muhammad Ayyoub',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.muhammadayoub',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_hudhaify',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Ali Al-Hudhaify',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.hudhaify',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_muhammad_jibreel',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Muhammad Jibreel',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.muhammadjibreel',
    bitrate: 128,
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'english_rwwad_audio',
    sourceId: englishTranslationId,
    languageCode: 'en',
    code: 'RWD-EN',
    title: 'English Translation',
    attribution: 'Rowwad Translation Center · QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'english_rwwad',
  ),
  QuranAudioInfo(
    id: 'french_rashid_audio',
    sourceId: 'french_rashid',
    languageCode: 'fr',
    code: 'RSH-FR',
    title: 'Traduction française',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'french_rashid',
  ),
  QuranAudioInfo(
    id: 'portuguese_nasr_audio',
    sourceId: 'portuguese_nasr',
    languageCode: 'pt',
    code: 'NASR-PT',
    title: 'Tradução portuguesa',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'portuguese_nasr',
  ),
  QuranAudioInfo(
    id: 'dutch_center_audio',
    sourceId: 'dutch_center',
    languageCode: 'nl',
    code: 'CTR-NL',
    title: 'Nederlandse vertaling',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'dutch_center',
  ),
  QuranAudioInfo(
    id: 'tagalog_rwwad_audio',
    sourceId: 'tagalog_rwwad',
    languageCode: 'tl',
    code: 'RWD-TL',
    title: 'Salin sa Tagalog',
    attribution: 'Rowwad Translation Center · QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'tagalog_rwwad',
  ),
  QuranAudioInfo(
    id: 'chinese_suliman_audio',
    sourceId: 'chinese_suliman',
    languageCode: 'zh',
    code: 'SLM-ZH',
    title: '中文翻译',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'chinese_suliman',
  ),
  QuranAudioInfo(
    id: 'vietnamese_rwwad_audio',
    sourceId: 'vietnamese_rwwad',
    languageCode: 'vi',
    code: 'RWD-VI',
    title: 'Bản dịch tiếng Việt',
    attribution: 'Rowwad Translation Center · QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'vietnamese_rwwad',
  ),
  QuranAudioInfo(
    id: 'persian_ih_audio',
    sourceId: 'persian_ih',
    languageCode: 'fa',
    code: 'IH-FA',
    title: 'ترجمه فارسی',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'persian_ih',
  ),
  QuranAudioInfo(
    id: 'assamese_rafeeq_audio',
    sourceId: 'assamese_rafeeq',
    languageCode: 'as',
    code: 'RAF-AS',
    title: 'অসমীয়া অনুবাদ',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'assamese_rafeeq',
  ),
  QuranAudioInfo(
    id: 'sinhalese_mahir_audio',
    sourceId: 'sinhalese_mahir',
    languageCode: 'si',
    code: 'MHR-SI',
    title: 'සිංහල පරිවර්තනය',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'sinhalese_mahir',
  ),
  QuranAudioInfo(
    id: 'somali_yacob_audio',
    sourceId: 'somali_yacob',
    languageCode: 'so',
    code: 'YCB-SO',
    title: 'Tarjumaadda Soomaaliga',
    attribution: 'QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'somali_yacob',
  ),
  QuranAudioInfo(
    id: 'turkish_vakfi_audio',
    sourceId: turkishVakfiTranslationId,
    languageCode: 'tr',
    code: 'VAKFI-TR',
    title: 'Diyanet Vakfı Sesli Meal',
    attribution: 'Islamic Network · 1MuslimApp · 128 kbps',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'tr.vakfi-audio',
    bitrate: 128,
  ),
];

List<QuranAudioInfo> quranAudioForSource(String sourceId) => quranAudioCatalog
    .where((audio) => audio.sourceId == sourceId)
    .toList(growable: false);

QuranAudioInfo? quranAudioById(String id) {
  for (final audio in quranAudioCatalog) {
    if (audio.id == id) return audio;
  }
  return null;
}

QuranAudioInfo? primaryQuranAudioForSource(String sourceId) {
  for (final audio in quranAudioCatalog) {
    if (audio.sourceId == sourceId) return audio;
  }
  return null;
}

bool hasQuranAudioForSource(String sourceId) =>
    primaryQuranAudioForSource(sourceId) != null;
''', encoding='utf-8')


# ---------------------------------------------------------------------------
# Translation catalog: multiple Turkish meals, all QuranEnc spoken languages,
# plus the Turkish Vakfi text that exactly matches its spoken edition.
# ---------------------------------------------------------------------------
Path('lib/src/data/translation_catalog.dart').write_text(r'''const arabicOriginalSourceId = 'arabic_original';
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
''', encoding='utf-8')


# ---------------------------------------------------------------------------
# Translation repository: QuranEnc remains primary; Islamic Network is added
# only for explicitly catalogued editions such as tr.vakfi.
# ---------------------------------------------------------------------------
path = Path('lib/src/data/translation_repository.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    """    if (!info.downloadable) {
      throw StateError('Translation is not enabled for download: ${info.id}');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
""",
    """    if (!info.downloadable) {
      throw StateError('Translation is not enabled for download: ${info.id}');
    }
    if (info.provider == TranslationProvider.islamicNetwork) {
      await _downloadIslamicNetworkTranslation(info, onProgress: onProgress);
      return;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
""",
    'translation provider dispatch',
)
text = replace_once(
    text,
    """      if (upstreamVersion.isNotEmpty && upstreamVersion != info.version) {
""",
    """      if (info.version != 'latest' &&
          upstreamVersion.isNotEmpty &&
          upstreamVersion != info.version) {
""",
    'allow reviewed latest catalog entries',
)
text = replace_once(
    text,
    """  Future<List<Map<String, dynamic>>> _fetchSurah(
""",
    r'''  Future<void> _downloadIslamicNetworkTranslation(
    TranslationInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final items = <Map<String, dynamic>>[];
      final seen = <String>{};
      const concurrency = 6;
      for (var start = 1; start <= 114; start += concurrency) {
        final end = math.min(start + concurrency - 1, 114);
        final chunks = await Future.wait([
          for (var surah = start; surah <= end; surah++)
            _fetchIslamicNetworkSurah(client, info, surah),
        ]);
        for (final chunk in chunks) {
          for (final raw in chunk) {
            final surah = int.tryParse('${raw['sura']}');
            final ayah = int.tryParse('${raw['aya']}');
            final translation = raw['translation'];
            if (surah == null ||
                surah < 1 ||
                surah > 114 ||
                ayah == null ||
                ayah < 1 ||
                translation is! String ||
                translation.trim().isEmpty) {
              throw const FormatException(
                'Islamic Network returned an invalid verse.',
              );
            }
            final key = '$surah:$ayah';
            if (!seen.add(key)) {
              throw FormatException(
                'Islamic Network returned duplicate verse $key.',
              );
            }
            items.add(raw);
          }
        }
        onProgress?.call(.02 + .96 * (end / 114));
      }

      if (items.length < 6000) {
        throw FormatException(
          'Downloaded translation looks incomplete: ${items.length} verses.',
        );
      }
      final package = <String, dynamic>{
        'schema_version': 1,
        'source': info.source,
        'source_key': info.sourceKey,
        'language_iso_code': info.languageCode,
        'version': info.version,
        'title': info.name,
        'description': info.publisher,
        'terms': const <String, dynamic>{
          'provider': 'Islamic Network / Al Quran Cloud',
          'attribution_required': true,
          'preserve_translation_identity': true,
        },
        'items': items,
      };
      final encoded = utf8.encode(jsonEncode(package));
      final compressed = Uint8List.fromList(gzip.encode(encoded));
      decodeGzipPack(
        compressed,
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );
      final file = await _downloadFile(info.id);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(compressed, flush: true);
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
      _downloadedPackFutures.remove(info.id);
      onProgress?.call(1);
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchIslamicNetworkSurah(
    HttpClient client,
    TranslationInfo info,
    int surah,
  ) async {
    final uri = Uri.https(
      'api.alquran.cloud',
      '/v1/surah/$surah/${info.sourceKey}',
    );
    final payload = await _getJson(client, uri);
    if (payload is! Map || payload['data'] is! Map) {
      throw FormatException('Unexpected Islamic Network response for surah $surah.');
    }
    final data = Map<String, dynamic>.from(payload['data'] as Map);
    final ayahs = data['ayahs'];
    if (ayahs is! List) {
      throw FormatException('Islamic Network ayahs missing for surah $surah.');
    }
    return [
      for (final raw in ayahs)
        if (raw is Map)
          <String, dynamic>{
            'sura': surah,
            'aya': raw['numberInSurah'],
            'translation': raw['text'],
          },
    ];
  }

  Future<List<Map<String, dynamic>>> _fetchSurah(
''',
    'islamic network downloader',
)
text = text.replace(
    "'QuranEnc returned HTTP ${response.statusCode}.'",
    "'${uri.host} returned HTTP ${response.statusCode}.'",
)
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# App settings: remember the selected human recording separately for each
# Quran/translation source.
# ---------------------------------------------------------------------------
path = Path('lib/src/settings/app_settings.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "  static const _readerTextSizeKey = 'reader_text_size';\n",
    "  static const _readerTextSizeKey = 'reader_text_size';\n  static const _selectedAudioBySourceKey = 'selected_audio_by_source_v1';\n",
    'audio settings key',
)
text = replace_once(
    text,
    "  Set<String> _readingDays = <String>{};\n",
    "  Set<String> _readingDays = <String>{};\n  Map<String, String> _selectedAudioBySource = <String, String>{};\n",
    'audio settings field',
)
text = replace_once(
    text,
    "  bool get readerUsesArabic => _selectedQuranSourceId == arabicOriginalSourceId;\n",
    "  bool get readerUsesArabic => _selectedQuranSourceId == arabicOriginalSourceId;\n\n  String? selectedAudioSourceFor(String sourceId) =>\n      _selectedAudioBySource[sourceId];\n",
    'audio settings getter',
)
text = replace_once(
    text,
    """    _readingDays = (prefs.getStringList(_readingDaysKey) ?? const <String>[])
        .toSet();
""",
    """    _readingDays = (prefs.getStringList(_readingDaysKey) ?? const <String>[])
        .toSet();
    _selectedAudioBySource = _decodeStringMap(
      prefs.getString(_selectedAudioBySourceKey),
    );
""",
    'audio settings load',
)
text = replace_once(
    text,
    """  Future<void> setReaderMode(ReaderDisplayMode mode) => setSelectedQuranSource(
""",
    r'''  Future<void> setSelectedAudioSource(
    String sourceId,
    String audioId,
  ) async {
    final source = sourceId.trim();
    final audio = audioId.trim();
    if (source.isEmpty || audio.isEmpty) return;
    if (_selectedAudioBySource[source] == audio) return;
    _selectedAudioBySource[source] = audio;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedAudioBySourceKey,
      jsonEncode(_selectedAudioBySource),
    );
  }

  Future<void> setReaderMode(ReaderDisplayMode mode) => setSelectedQuranSource(
''',
    'audio settings setter',
)
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Reader audio engine: generic provider URLs and source selector in the sheet.
# ---------------------------------------------------------------------------
path = Path('lib/src/features/reader/reader_audio_sheet.dart')
text = path.read_text(encoding='utf-8')
pattern = re.compile(
    r"ReaderAudioSourceConfig\? readerAudioConfigFor\(String sourceId\) \{.*?\n\}\n\nclass ReaderAudioController",
    re.S,
)
replacement = r'''int _absoluteVerseNumber(int surah, int ayah) {
  var value = ayah;
  for (var previous = 1; previous < surah; previous++) {
    value += quran.getVerseCount(previous);
  }
  return value;
}

ReaderAudioSourceConfig? readerAudioConfigFor(
  String sourceId, {
  String? audioId,
}) {
  final available = quranAudioForSource(sourceId);
  if (available.isEmpty) return null;
  var audio = available.first;
  if (audioId != null) {
    for (final candidate in available) {
      if (candidate.id == audioId) {
        audio = candidate;
        break;
      }
    }
  }

  return ReaderAudioSourceConfig(
    id: audio.id,
    code: audio.code,
    title: audio.style == null ? audio.title : '${audio.title} · ${audio.style}',
    urlForVerse: (surah, ayah) {
      if (audio.provider == QuranAudioProvider.quranEnc) {
        final s = surah.toString().padLeft(3, '0');
        final a = ayah.toString().padLeft(3, '0');
        return 'https://d.quranenc.com/data/audio/${audio.providerKey}/$s$a.mp3';
      }
      final absolute = _absoluteVerseNumber(surah, ayah);
      final bitrate = audio.bitrate ?? 128;
      return 'https://cdn.islamic.network/quran/audio/$bitrate/${audio.providerKey}/$absolute.mp3';
    },
  );
}

class ReaderAudioController'''
text, count = pattern.subn(replacement, text, count=1)
if count != 1:
    raise SystemExit('missing patch target: reader audio config block')
text = replace_once(
    text,
    """    required this.quickControlsVisible,
    required this.onQuickControlsVisibilityChanged,
    super.key,
""",
    """    required this.quickControlsVisible,
    required this.onQuickControlsVisibilityChanged,
    required this.availableSources,
    required this.onSourceSelected,
    super.key,
""",
    'audio sheet constructor',
)
text = replace_once(
    text,
    """  final ValueChanged<bool> onQuickControlsVisibilityChanged;
""",
    """  final ValueChanged<bool> onQuickControlsVisibilityChanged;
  final List<QuranAudioInfo> availableSources;
  final Future<void> Function(String audioId) onSourceSelected;
""",
    'audio sheet fields',
)
old_header = """                          Text(
                            '${controller.config?.code ?? ''} · ${controller.config?.title ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
"""
new_header = """                          if (widget.availableSources.length <= 1)
                            Text(
                              '${controller.config?.code ?? ''} · ${controller.config?.title ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            )
                          else
                            PopupMenuButton<String>(
                              initialValue: controller.config?.id,
                              onSelected: (value) => unawaited(
                                widget.onSourceSelected(value),
                              ),
                              itemBuilder: (_) => [
                                for (final source in widget.availableSources)
                                  PopupMenuItem<String>(
                                    value: source.id,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          source.style == null
                                              ? source.title
                                              : '${source.title} · ${source.style}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          source.attribution,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${controller.config?.code ?? ''} · ${controller.config?.title ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
"""
text = replace_once(text, old_header, new_header, 'audio source menu')
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Reader: use the saved audio choice and let the audio sheet change it.
# ---------------------------------------------------------------------------
path = Path('lib/src/features/reader/quran_reader_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../data/quran_verse_metadata.dart';\n",
    "import '../../data/quran_audio_catalog.dart';\nimport '../../data/quran_verse_metadata.dart';\n",
    'reader audio catalog import',
)
text = replace_once(
    text,
    """  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) =>
      readerAudioConfigFor(settings.selectedQuranSourceId);
""",
    """  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) =>
      readerAudioConfigFor(
        settings.selectedQuranSourceId,
        audioId: settings.selectedAudioSourceFor(settings.selectedQuranSourceId),
      );
""",
    'reader selected audio config',
)
text = replace_once(
    text,
    """  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {
""",
    r'''  Future<void> _selectAudioSource(String audioId) async {
    final settings = AppSettingsScope.of(context);
    final sourceId = settings.selectedQuranSourceId;
    final candidates = quranAudioForSource(sourceId);
    if (!candidates.any((audio) => audio.id == audioId)) return;
    final currentAyah = _audioController.isConfigured &&
            _audioController.surahNumber == _surahNumber
        ? _audioController.currentAyah
        : 1;
    await settings.setSelectedAudioSource(sourceId, audioId);
    final config = readerAudioConfigFor(sourceId, audioId: audioId);
    if (config == null) return;
    final surah = surahByNumber(_surahNumber);
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: currentAyah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
    if (mounted) setState(() {});
  }

  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {
''',
    'reader audio source selection method',
)
text = replace_once(
    text,
    """        quickControlsVisible: _audioQuickControlsVisible,
        onQuickControlsVisibilityChanged: (visible) {
          if (mounted) setState(() => _audioQuickControlsVisible = visible);
        },
""",
    """        quickControlsVisible: _audioQuickControlsVisible,
        onQuickControlsVisibilityChanged: (visible) {
          if (mounted) setState(() => _audioQuickControlsVisible = visible);
        },
        availableSources: quranAudioForSource(
          AppSettingsScope.of(context).selectedQuranSourceId,
        ),
        onSourceSelected: _selectAudioSource,
""",
    'reader audio sheet source args',
)
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Translation discovery: Audio tab should show one row per text source, not
# twelve duplicate Arabic rows; add friendly language names for new languages.
# ---------------------------------------------------------------------------
path = Path('lib/src/features/settings/quran_translation_catalog_screen.dart')
text = path.read_text(encoding='utf-8')
old_audio_filter = """      case _TranslationFilter.audio:
        filtered = quranAudioCatalog
            .map((audio) => _audioDiscoveryItem(context, audio))
            .where((item) => _matches(context, item));
        break;
"""
new_audio_filter = """      case _TranslationFilter.audio:
        final seenSources = <String>{};
        filtered = quranAudioCatalog
            .where((audio) => seenSources.add(audio.sourceId))
            .map((audio) => _audioDiscoveryItem(context, audio))
            .where((item) => _matches(context, item));
        break;
"""
text = replace_once(text, old_audio_filter, new_audio_filter, 'audio discovery dedupe')
lang_pattern = re.compile(
    r"  String languageName\(String code\) => switch \(code\) \{.*?\n  \};\n\n  String nativeLanguageName\(String code\) => switch \(code\) \{.*?\n  \};",
    re.S,
)
lang_replacement = r'''  String languageName(String code) => switch (code) {
    'tr' => _pick(tr: 'Türkçe', en: 'Turkish', ar: 'التركية', az: 'Türkcə', ru: 'Турецкий'),
    'en' => _pick(tr: 'İngilizce', en: 'English', ar: 'الإنجليزية', az: 'İngiliscə', ru: 'Английский'),
    'az' => _pick(tr: 'Azerbaycanca', en: 'Azerbaijani', ar: 'الأذربيجانية', az: 'Azərbaycanca', ru: 'Азербайджанский'),
    'ru' => _pick(tr: 'Rusça', en: 'Russian', ar: 'الروسية', az: 'Rusca', ru: 'Русский'),
    'ar' => _pick(tr: 'Arapça', en: 'Arabic', ar: 'العربية', az: 'Ərəbcə', ru: 'Арабский'),
    'fr' => _pick(tr: 'Fransızca', en: 'French', ar: 'الفرنسية', az: 'Fransızca', ru: 'Французский'),
    'pt' => _pick(tr: 'Portekizce', en: 'Portuguese', ar: 'البرتغالية', az: 'Portuqalca', ru: 'Португальский'),
    'nl' => _pick(tr: 'Felemenkçe', en: 'Dutch', ar: 'الهولندية', az: 'Niderlandca', ru: 'Нидерландский'),
    'tl' => _pick(tr: 'Tagalogca', en: 'Tagalog', ar: 'التاغالوغية', az: 'Taqaloqca', ru: 'Тагальский'),
    'zh' => _pick(tr: 'Çince', en: 'Chinese', ar: 'الصينية', az: 'Çincə', ru: 'Китайский'),
    'vi' => _pick(tr: 'Vietnamca', en: 'Vietnamese', ar: 'الفيتنامية', az: 'Vyetnamca', ru: 'Вьетнамский'),
    'fa' => _pick(tr: 'Farsça', en: 'Persian', ar: 'الفارسية', az: 'Farsca', ru: 'Персидский'),
    'as' => _pick(tr: 'Assamca', en: 'Assamese', ar: 'الأسامية', az: 'Assamca', ru: 'Ассамский'),
    'si' => _pick(tr: 'Sinhala', en: 'Sinhala', ar: 'السنهالية', az: 'Sinhala', ru: 'Сингальский'),
    'so' => _pick(tr: 'Somalice', en: 'Somali', ar: 'الصومالية', az: 'Somalicə', ru: 'Сомалийский'),
    _ => code.toUpperCase(),
  };

  String nativeLanguageName(String code) => switch (code) {
    'tr' => 'Türkçe',
    'en' => 'English',
    'az' => 'Azərbaycanca',
    'ru' => 'Русский',
    'ar' => 'العربية',
    'fr' => 'Français',
    'pt' => 'Português',
    'nl' => 'Nederlands',
    'tl' => 'Tagalog',
    'zh' => '中文',
    'vi' => 'Tiếng Việt',
    'fa' => 'فارسی',
    'as' => 'অসমীয়া',
    'si' => 'සිංහල',
    'so' => 'Soomaali',
    _ => code.toUpperCase(),
  };'''
text, count = lang_pattern.subn(lang_replacement, text, count=1)
if count != 1:
    raise SystemExit('missing patch target: translation language names')
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Tests for one-to-one source/audio matching and expanded catalog.
# ---------------------------------------------------------------------------
path = Path('test/translation_catalog_test.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    """  test('audio catalog includes Arabic recitation and English spoken translation', () {
    final arabic = primaryQuranAudioForSource(arabicOriginalSourceId);
    final english = primaryQuranAudioForSource(englishTranslationId);

    expect(arabic, isNotNull);
    expect(arabic!.kind, QuranAudioKind.recitation);
    expect(arabic.title, 'Mishary Rashid Alafasy');
    expect(english, isNotNull);
    expect(english!.kind, QuranAudioKind.translation);
    expect(hasQuranAudioForSource(bundledTurkishTranslationId), isFalse);
  });
""",
    """  test('audio catalog keeps recordings attached to their exact text source', () {
    final arabic = quranAudioForSource(arabicOriginalSourceId);
    final english = primaryQuranAudioForSource(englishTranslationId);
    final vakfi = primaryQuranAudioForSource(turkishVakfiTranslationId);

    expect(arabic.length, greaterThanOrEqualTo(10));
    expect(arabic.first.title, 'Mishary Rashid Alafasy');
    expect(arabic.every((item) => item.kind == QuranAudioKind.recitation), isTrue);
    expect(english, isNotNull);
    expect(english!.providerKey, 'english_rwwad');
    expect(vakfi, isNotNull);
    expect(vakfi!.providerKey, 'tr.vakfi-audio');
    expect(hasQuranAudioForSource(bundledTurkishTranslationId), isFalse);
    expect(quranAudioCatalog.where((item) => item.kind == QuranAudioKind.translation).length, greaterThanOrEqualTo(12));
  });

  test('Turkish catalog exposes multiple human translations', () {
    final turkish = translationCatalog.where((item) => item.languageCode == 'tr').toList();
    expect(turkish.length, greaterThanOrEqualTo(4));
    expect(translationById(turkishShabanTranslationId)?.sourceKey, 'turkish_shaban');
    expect(translationById(turkishAliOzekTranslationId)?.sourceKey, 'turkish_shahin');
    expect(translationById(turkishVakfiTranslationId)?.provider, TranslationProvider.islamicNetwork);
  });
""",
    'translation catalog audio tests',
)
path.write_text(text, encoding='utf-8')
