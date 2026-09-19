import 'translation_catalog.dart';

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
    this.availableBitrates = const <int>[],
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
  final List<int> availableBitrates;
  final String? style;
}

const quranAudioCatalog = <QuranAudioInfo>[
  QuranAudioInfo(id: 'arabic_recitation_alafasy', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Mishary Rashid Alafasy', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.alafasy', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_husary', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Mahmoud Khalil Al-Husary', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.husary', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_minshawi', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Mohamed Siddiq Al-Minshawi', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.minshawi', bitrate: 128, style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_minshawi_mujawwad', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Mohamed Siddiq Al-Minshawi', attribution: 'Islamic Network · Al Quran Cloud · 64 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.minshawimujawwad', bitrate: 64, style: 'Mujawwad'),
  QuranAudioInfo(id: 'arabic_recitation_sudais', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Abdul Rahman Al-Sudais', attribution: 'Islamic Network · Al Quran Cloud · 192 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.abdurrahmaansudais', bitrate: 192, availableBitrates: <int>[64, 192], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_shuraim', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Saud Al-Shuraim', attribution: 'Islamic Network · Al Quran Cloud · 64 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.saoodshuraym', bitrate: 64, style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_abdulbasit', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Abdul Basit Abdul Samad', attribution: 'Islamic Network · Al Quran Cloud · 192 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.abdulbasitmurattal', bitrate: 192, availableBitrates: <int>[64, 192], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_abdul_samad', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Abdul Samad', attribution: 'Islamic Network · Al Quran Cloud · 64 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.abdulsamad', bitrate: 64),
  QuranAudioInfo(id: 'arabic_recitation_ajamy', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Ahmed ibn Ali Al-Ajamy', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.ahmedajamy', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_muhammad_ayyoub', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Muhammad Ayyoub', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.muhammadayyoub', bitrate: 128, style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_hudhaify', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Ali Al-Hudhaify', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.hudhaify', bitrate: 128, availableBitrates: <int>[32, 64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_muhammad_jibreel', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Muhammad Jibreel', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.muhammadjibreel', bitrate: 128, style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_husary_mujawwad', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Mahmoud Khalil Al-Husary', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.husarymujawwad', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Mujawwad'),
  QuranAudioInfo(id: 'arabic_recitation_maher_muaiqly', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Maher Al Muaiqly', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.mahermuaiqly', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_shatri', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Abu Bakr Al-Shatri', attribution: 'Islamic Network · Al Quran Cloud · 128 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.shaatree', bitrate: 128, availableBitrates: <int>[64, 128], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_abdullah_basfar', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Abdullah Basfar', attribution: 'Islamic Network · Al Quran Cloud · 192 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.abdullahbasfar', bitrate: 192, availableBitrates: <int>[32, 64, 192], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_hani_rifai', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Hani Ar-Rifai', attribution: 'Islamic Network · Al Quran Cloud · 192 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.hanirifai', bitrate: 192, availableBitrates: <int>[64, 192], style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_ayman_sowaid', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Ayman Sowaid', attribution: 'Islamic Network · Al Quran Cloud · 64 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.aymanswoaid', bitrate: 64, style: 'Murattal'),
  QuranAudioInfo(id: 'arabic_recitation_ibrahim_akhdar', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Ibrahim Akhdar', attribution: 'Islamic Network · Al Quran Cloud · 32 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.ibrahimakhbar', bitrate: 32),
  QuranAudioInfo(id: 'arabic_recitation_parhizgar', sourceId: arabicOriginalSourceId, languageCode: 'ar', code: 'AR', title: 'Parhizgar', attribution: 'Islamic Network · Al Quran Cloud · 48 kbps', kind: QuranAudioKind.recitation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ar.parhizgar', bitrate: 48),
  QuranAudioInfo(id: 'english_rwwad_audio', sourceId: englishTranslationId, languageCode: 'en', code: 'RWD-EN', title: 'English Translation', attribution: 'Rowwad Translation Center · QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'english_rwwad'),
  QuranAudioInfo(id: 'french_rashid_audio', sourceId: 'french_rashid', languageCode: 'fr', code: 'RSH-FR', title: 'Traduction française', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'french_rashid'),
  QuranAudioInfo(id: 'portuguese_nasr_audio', sourceId: 'portuguese_nasr', languageCode: 'pt', code: 'NASR-PT', title: 'Tradução portuguesa', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'portuguese_nasr'),
  QuranAudioInfo(id: 'dutch_center_audio', sourceId: 'dutch_center', languageCode: 'nl', code: 'CTR-NL', title: 'Nederlandse vertaling', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'dutch_center'),
  QuranAudioInfo(id: 'tagalog_rwwad_audio', sourceId: 'tagalog_rwwad', languageCode: 'tl', code: 'RWD-TL', title: 'Salin sa Tagalog', attribution: 'Rowwad Translation Center · QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'tagalog_rwwad'),
  QuranAudioInfo(id: 'chinese_suliman_audio', sourceId: 'chinese_suliman', languageCode: 'zh', code: 'SLM-ZH', title: '中文翻译', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'chinese_suliman'),
  QuranAudioInfo(id: 'vietnamese_rwwad_audio', sourceId: 'vietnamese_rwwad', languageCode: 'vi', code: 'RWD-VI', title: 'Bản dịch tiếng Việt', attribution: 'Rowwad Translation Center · QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'vietnamese_rwwad'),
  QuranAudioInfo(id: 'persian_ih_audio', sourceId: 'persian_ih', languageCode: 'fa', code: 'IH-FA', title: 'ترجمه فارسی', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'persian_ih'),
  QuranAudioInfo(id: 'assamese_rafeeq_audio', sourceId: 'assamese_rafeeq', languageCode: 'as', code: 'RAF-AS', title: 'অসমীয়া অনুবাদ', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'assamese_rafeeq'),
  QuranAudioInfo(id: 'russian_kuliev_audio', sourceId: 'russian_kuliev', languageCode: 'ru', code: 'KUL-RU', title: 'Русский перевод · Эльмир Кулиев', attribution: 'Elmir Kuliev · Islamic Network · 128 kbps', kind: QuranAudioKind.translation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'ru.kuliev-audio', bitrate: 128),
  QuranAudioInfo(id: 'sinhalese_mahir_audio', sourceId: 'sinhalese_mahir', languageCode: 'si', code: 'MHR-SI', title: 'සිංහල පරිවර්තනය', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'sinhalese_mahir'),
  QuranAudioInfo(id: 'somali_yacob_audio', sourceId: 'somali_yacob', languageCode: 'so', code: 'YCB-SO', title: 'Tarjumaadda Soomaaliga', attribution: 'QuranEnc.com', kind: QuranAudioKind.translation, provider: QuranAudioProvider.quranEnc, providerKey: 'somali_yacob'),
  QuranAudioInfo(id: 'turkish_vakfi_audio', sourceId: turkishVakfiTranslationId, languageCode: 'tr', code: 'VAKFI-TR', title: 'Diyanet Vakfı Sesli Meal', attribution: 'Islamic Network · 1MuslimApp · 128 kbps', kind: QuranAudioKind.translation, provider: QuranAudioProvider.islamicNetwork, providerKey: 'tr.vakfi-audio', bitrate: 128),
];

/// Audio attached to a translation and Arabic recitation are separate choices.
/// A user can therefore keep any meal selected while listening to a verified
/// Arabic reciter. Source-specific spoken translations stay first so existing
/// defaults remain unchanged when no reciter has been explicitly selected.
List<QuranAudioInfo> quranAudioForSource(String sourceId) {
  final sourceAudio = quranAudioCatalog
      .where((audio) => audio.sourceId == sourceId)
      .toList(growable: false);
  if (sourceId == arabicOriginalSourceId) return sourceAudio;
  final recitations = quranAudioCatalog.where(
    (audio) =>
        audio.sourceId == arabicOriginalSourceId &&
        audio.kind == QuranAudioKind.recitation,
  );
  return <QuranAudioInfo>[...sourceAudio, ...recitations];
}

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

List<int> quranAudioBitrates(QuranAudioInfo audio) {
  if (audio.availableBitrates.isNotEmpty) {
    final values = audio.availableBitrates.toSet().toList()..sort();
    return values;
  }
  return audio.bitrate == null ? const <int>[] : <int>[audio.bitrate!];
}
