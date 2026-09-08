from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing fix target: {label}')
    return text.replace(old, new, 1)


# Main patch appends a lookup helper which already exists in the catalog.
path = Path('lib/src/data/quran_audio_catalog.dart')
text = path.read_text(encoding='utf-8')
duplicate = """
QuranAudioInfo? quranAudioById(String id) {
  for (final audio in quranAudioCatalog) {
    if (audio.id == id) return audio;
  }
  return null;
}

List<int> quranAudioBitrates(QuranAudioInfo audio) {
"""
replacement = """
List<int> quranAudioBitrates(QuranAudioInfo audio) {
"""
# Remove only the appended duplicate, leaving the existing lookup above intact.
if text.count('QuranAudioInfo? quranAudioById(String id)') != 2:
    raise SystemExit('unexpected quranAudioById definition count')
pos = text.rfind(duplicate)
if pos < 0:
    raise SystemExit('appended duplicate quranAudioById not found')
text = text[:pos] + replacement + text[pos + len(duplicate):]
path.write_text(text, encoding='utf-8')


# Continuation settings are needed in the two helper methods patched by the main script.
path = Path('lib/src/features/reader/quran_reader_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {\n    final surah = surahByNumber(_surahNumber);",
    "  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {\n    final settings = AppSettingsScope.of(context);\n    final surah = surahByNumber(_surahNumber);",
    'prepare audio settings',
)
text = replace_once(
    text,
    "  Future<void> _primeAudio(ReaderAudioSourceConfig config, int ayah) async {\n    final surah = surahByNumber(_surahNumber);",
    "  Future<void> _primeAudio(ReaderAudioSourceConfig config, int ayah) async {\n    final settings = AppSettingsScope.of(context);\n    final surah = surahByNumber(_surahNumber);",
    'prime audio settings',
)
path.write_text(text, encoding='utf-8')
