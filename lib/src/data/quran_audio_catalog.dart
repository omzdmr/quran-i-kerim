import 'translation_catalog.dart';

enum QuranAudioKind { recitation, translation }

class QuranAudioInfo {
  const QuranAudioInfo({
    required this.id,
    required this.sourceId,
    required this.languageCode,
    required this.code,
    required this.title,
    required this.attribution,
    required this.kind,
  });

  final String id;
  final String sourceId;
  final String languageCode;
  final String code;
  final String title;
  final String attribution;
  final QuranAudioKind kind;
}

const quranAudioCatalog = <QuranAudioInfo>[
  QuranAudioInfo(
    id: 'arabic_recitation_alafasy',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mishary Rashid Alafasy',
    attribution: 'Islamic Network · 64 kbps',
    kind: QuranAudioKind.recitation,
  ),
  QuranAudioInfo(
    id: 'english_rwwad_audio',
    sourceId: englishTranslationId,
    languageCode: 'en',
    code: 'RWD-EN',
    title: 'English Translation',
    attribution: 'Rowwad Translation Center · QuranEnc.com',
    kind: QuranAudioKind.translation,
  ),
];

List<QuranAudioInfo> quranAudioForSource(String sourceId) => quranAudioCatalog
    .where((audio) => audio.sourceId == sourceId)
    .toList(growable: false);

QuranAudioInfo? primaryQuranAudioForSource(String sourceId) {
  for (final audio in quranAudioCatalog) {
    if (audio.sourceId == sourceId) return audio;
  }
  return null;
}

bool hasQuranAudioForSource(String sourceId) =>
    primaryQuranAudioForSource(sourceId) != null;
