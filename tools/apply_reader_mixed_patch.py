from pathlib import Path
import hashlib

reader_path = Path('lib/src/features/reader/quran_reader_screen.dart')
widget_path = Path('lib/src/features/reader/reader_mixed_verse_list.dart')

reader = reader_path.read_text()
raw = reader.encode()
actual = hashlib.sha1(f'blob {len(raw)}\0'.encode() + raw).hexdigest()
expected = '8f68a5d3a014e6ad5a990634f3a7086aeb3122eb'
if actual != expected:
    raise SystemExit(f'Reader blob changed: expected {expected}, got {actual}')

replacements = [
    (
        "import '../../data/translation_repository.dart';\n",
        "import '../../data/translation_repository.dart';\nimport '../../data/transliteration_repository.dart';\n",
    ),
    (
        "import 'reader_navigation.dart';\n",
        "import 'reader_navigation.dart';\nimport 'reader_mixed_verse_list.dart';\n",
    ),
    (
        "  final GlobalKey<_ContinuousVerseTextState> _textKey =\n      GlobalKey<_ContinuousVerseTextState>();\n",
        "  final GlobalKey<_ContinuousVerseTextState> _textKey =\n      GlobalKey<_ContinuousVerseTextState>();\n  final GlobalKey<ReaderMixedVerseListState> _mixedTextKey =\n      GlobalKey<ReaderMixedVerseListState>();\n",
    ),
    (
        "      final state = _textKey.currentState;\n      final globalY = state?.globalYForAyah(ayah);\n",
        "      final settings = AppSettingsScope.of(context);\n      final globalY = settings.readerUsesArabic\n          ? _textKey.currentState?.globalYForAyah(ayah)\n          : _mixedTextKey.currentState?.globalYForAyah(ayah);\n",
    ),
    (
        "    final targetY = MediaQuery.paddingOf(context).top + 100;\n    final ayah = _textKey.currentState?.ayahClosestToGlobalY(targetY);\n    if (ayah == null) return;\n    if (_visibleAyah != ayah) {\n      setState(() => _visibleAyah = ayah);\n    }\n    final settings = AppSettingsScope.of(context);\n",
        "    final targetY = MediaQuery.paddingOf(context).top + 100;\n    final settings = AppSettingsScope.of(context);\n    final ayah = settings.readerUsesArabic\n        ? _textKey.currentState?.ayahClosestToGlobalY(targetY)\n        : _mixedTextKey.currentState?.ayahClosestToGlobalY(targetY);\n    if (ayah == null) return;\n    if (_visibleAyah != ayah) {\n      setState(() => _visibleAyah = ayah);\n    }\n",
    ),
    (
        "          if (arabicMode && hasSeparateBasmala) ...[\n",
        "          if (hasSeparateBasmala) ...[\n",
    ),
]

old_render = """              _ContinuousVerseText(
                key: _textKey,
                surahNumber: _surahNumber,
                verseCount: surah.verseCount,
                translations: translations,
                footnotes: footnotes,
                mode: settings.readerMode,
                textSize: settings.readerTextSize,
                lineHeight: settings.readerUsesArabic
                    ? settings.arabicLineHeight
                    : settings.translationLineHeight,
                selectedAyahs: _selectedAyahs,
                activeAudioAyah:
                    _audioController.isPlaying &&
                        _audioController.surahNumber == _surahNumber
                    ? _audioController.currentAyah
                    : null,
                settings: settings,
                onAyahTap: _toggleAyahSelection,
                onNoteTap: _openNoteForAyah,
                onFootnoteTap: _showFootnoteForAyah,
              ),
"""
new_render = """              if (settings.readerUsesArabic)
                _ContinuousVerseText(
                  key: _textKey,
                  surahNumber: _surahNumber,
                  verseCount: surah.verseCount,
                  translations: translations,
                  footnotes: footnotes,
                  mode: settings.readerMode,
                  textSize: settings.readerTextSize,
                  lineHeight: settings.arabicLineHeight,
                  selectedAyahs: _selectedAyahs,
                  activeAudioAyah:
                      _audioController.isPlaying &&
                          _audioController.surahNumber == _surahNumber
                      ? _audioController.currentAyah
                      : null,
                  settings: settings,
                  onAyahTap: _toggleAyahSelection,
                  onNoteTap: _openNoteForAyah,
                  onFootnoteTap: _showFootnoteForAyah,
                )
              else
                FutureBuilder<Map<String, String>>(
                  future: TransliterationRepository.instance.loadBundled(),
                  builder: (context, snapshot) {
                    final info = translationById(
                      settings.selectedQuranSourceId,
                    );
                    return ReaderMixedVerseList(
                      key: _mixedTextKey,
                      surahNumber: _surahNumber,
                      verseCount: surah.verseCount,
                      arabicForAyah: (ayah) =>
                          quran.getVerse(_surahNumber, ayah),
                      transliterations:
                          snapshot.data ?? const <String, String>{},
                      translations: translations,
                      footnotes: footnotes,
                      translationLanguageCode:
                          info?.languageCode ??
                          Localizations.localeOf(context).languageCode,
                      arabicTextSize: settings.arabicFontSize,
                      translationTextSize: settings.translationFontSize,
                      arabicLineHeight: settings.arabicLineHeight,
                      translationLineHeight: settings.translationLineHeight,
                      selectedAyahs: _selectedAyahs,
                      activeAudioAyah:
                          _audioController.isPlaying &&
                              _audioController.surahNumber == _surahNumber
                          ? _audioController.currentAyah
                          : null,
                      settings: settings,
                      onAyahTap: _toggleAyahSelection,
                      onNoteTap: _openNoteForAyah,
                      onFootnoteTap: _showFootnoteForAyah,
                    );
                  },
                ),
"""
replacements.append((old_render, new_render))

for old, new in replacements:
    count = reader.count(old)
    if count != 1:
        raise SystemExit(f'Expected one reader anchor, found {count}: {old[:70]!r}')
    reader = reader.replace(old, new, 1)
reader_path.write_text(reader)

widget = widget_path.read_text()
old = "                    fontSize: (translationTextSize * .72).clamp(13, 20),\n"
new = "                    fontSize: (translationTextSize * .72)\n                        .clamp(13.0, 20.0)\n                        .toDouble(),\n"
if widget.count(old) != 1:
    raise SystemExit('Expected one transliteration font-size anchor')
widget_path.write_text(widget.replace(old, new, 1))
