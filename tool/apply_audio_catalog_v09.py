from pathlib import Path

ROOT = Path('.')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


# Settings/discovery screen: source Audio Available from the audio catalog,
# including Arabic original recitation.
path = ROOT / 'lib/src/features/settings/quran_translation_catalog_screen.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../data/translation_catalog.dart';\n",
    "import '../../data/quran_audio_catalog.dart';\nimport '../../data/translation_catalog.dart';\n",
    'settings audio catalog import',
)
text = replace_once(
    text,
    "            hasAudio: selectedInfo?.hasAudio ?? false,",
    "            hasAudio: hasQuranAudioForSource(selectedId),",
    'current source audio flag',
)
text = replace_once(
    text,
    "        hasAudio: false,\n      );",
    "        hasAudio: hasQuranAudioForSource(arabicOriginalSourceId),\n      );",
    'installed Arabic audio flag',
)
text = replace_once(
    text,
    "        hasAudio: info.hasAudio,\n        info: info,",
    "        hasAudio: hasQuranAudioForSource(info.id),\n        info: info,",
    'installed translation audio flag',
)
old_visible = '''  List<TranslationInfo> _visibleItems(BuildContext context) {
    final uiLanguage = Localizations.localeOf(context).languageCode;
    final all = translationCatalog
        .where((item) => item.available && _matches(context, item))
        .toList(growable: false);

    Iterable<TranslationInfo> filtered;
    switch (_filter) {
      case _TranslationFilter.recommended:
        final sameLanguage = all
            .where((item) => item.languageCode == uiLanguage)
            .toList(growable: false);
        filtered = sameLanguage.isEmpty ? all : sameLanguage;
        break;
      case _TranslationFilter.all:
        filtered = all;
        break;
      case _TranslationFilter.audio:
        filtered = all.where((item) => item.hasAudio);
        break;
    }

    final copy = _TranslationUiCopy.of(context);
    final result = filtered.toList(growable: false)
      ..sort((a, b) {
        if (a.languageCode == uiLanguage && b.languageCode != uiLanguage) {
          return -1;
        }
        if (b.languageCode == uiLanguage && a.languageCode != uiLanguage) {
          return 1;
        }
        final languageCompare = copy
            .languageName(a.languageCode)
            .compareTo(copy.languageName(b.languageCode));
        if (languageCompare != 0) return languageCompare;
        return a.name.compareTo(b.name);
      });
    return result;
  }
'''
new_visible = '''  TranslationInfo _audioDiscoveryItem(
    BuildContext context,
    QuranAudioInfo audio,
  ) {
    final linked = translationById(audio.sourceId);
    if (linked != null) return linked;
    final copy = _TranslationUiCopy.of(context);
    return TranslationInfo(
      id: audio.sourceId,
      code: audio.code,
      languageCode: audio.languageCode,
      name: audio.sourceId == arabicOriginalSourceId
          ? copy.arabicOriginal
          : audio.title,
      publisher: audio.title,
      source: audio.attribution,
      sourceKey: audio.id,
      version: 'audio',
      bundled: true,
      available: true,
      downloadable: false,
      hasAudio: true,
    );
  }

  List<TranslationInfo> _visibleItems(BuildContext context) {
    final uiLanguage = Localizations.localeOf(context).languageCode;
    final all = translationCatalog
        .where((item) => item.available && _matches(context, item))
        .toList(growable: false);

    Iterable<TranslationInfo> filtered;
    switch (_filter) {
      case _TranslationFilter.recommended:
        final sameLanguage = all
            .where((item) => item.languageCode == uiLanguage)
            .toList(growable: false);
        filtered = sameLanguage.isEmpty ? all : sameLanguage;
        break;
      case _TranslationFilter.all:
        filtered = all;
        break;
      case _TranslationFilter.audio:
        filtered = quranAudioCatalog
            .map((audio) => _audioDiscoveryItem(context, audio))
            .where((item) => _matches(context, item));
        break;
    }

    final copy = _TranslationUiCopy.of(context);
    final result = filtered.toList(growable: false)
      ..sort((a, b) {
        if (a.languageCode == uiLanguage && b.languageCode != uiLanguage) {
          return -1;
        }
        if (b.languageCode == uiLanguage && a.languageCode != uiLanguage) {
          return 1;
        }
        final languageCompare = copy
            .languageName(a.languageCode)
            .compareTo(copy.languageName(b.languageCode));
        if (languageCompare != 0) return languageCompare;
        return a.name.compareTo(b.name);
      });
    return result;
  }
'''
text = replace_once(text, old_visible, new_visible, 'audio discovery source')
path.write_text(text, encoding='utf-8')


# Reader player: use the same catalog as the discovery UI.
path = ROOT / 'lib/src/features/reader/reader_audio_sheet.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../data/translation_catalog.dart';\n",
    "import '../../data/quran_audio_catalog.dart';\nimport '../../data/translation_catalog.dart';\n",
    'reader audio catalog import',
)
old_config = '''ReaderAudioSourceConfig? readerAudioConfigFor(String sourceId) {
  if (sourceId == arabicOriginalSourceId) {
    return ReaderAudioSourceConfig(
      id: 'arabic_recitation_alafasy',
      code: 'AR',
      title: 'Mishary Rashid Alafasy',
      urlForVerse: (surah, ayah) =>
          quran.getAudioURLByVerse(surah, ayah, bitrate: 64),
    );
  }

  final info = translationById(sourceId);
  if (info == null || !info.hasAudio || info.sourceKey != 'english_rwwad') {
    return null;
  }

  return ReaderAudioSourceConfig(
    id: info.id,
    code: info.code,
    title: info.name,
    urlForVerse: (surah, ayah) {
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      return 'https://d.quranenc.com/data/audio/${info.sourceKey}/$s$a.mp3';
    },
  );
}
'''
new_config = '''ReaderAudioSourceConfig? readerAudioConfigFor(String sourceId) {
  final audio = primaryQuranAudioForSource(sourceId);
  if (audio == null) return null;

  if (audio.kind == QuranAudioKind.recitation) {
    return ReaderAudioSourceConfig(
      id: audio.id,
      code: audio.code,
      title: audio.title,
      urlForVerse: (surah, ayah) =>
          quran.getAudioURLByVerse(surah, ayah, bitrate: 64),
    );
  }

  final info = translationById(sourceId);
  if (info == null || info.sourceKey != 'english_rwwad') return null;
  return ReaderAudioSourceConfig(
    id: audio.id,
    code: audio.code,
    title: audio.title,
    urlForVerse: (surah, ayah) {
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      return 'https://d.quranenc.com/data/audio/${info.sourceKey}/$s$a.mp3';
    },
  );
}
'''
text = replace_once(text, old_config, new_config, 'reader audio config')
path.write_text(text, encoding='utf-8')
