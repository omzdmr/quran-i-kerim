from pathlib import Path
import subprocess


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f'missing anchor: {label}')
    return text.replace(old, new, 1)

catalog_path = Path('lib/src/data/quran_audio_catalog.dart')
catalog = catalog_path.read_text(encoding='utf-8')

old_abdul = '''  QuranAudioInfo(
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
'''
new_abdul = '''  QuranAudioInfo(
    id: 'arabic_recitation_abdul_samad',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abdul Samad',
    attribution: 'Islamic Network · Al Quran Cloud · 64 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.abdulsamad',
    bitrate: 64,
  ),
'''
catalog = replace_once(catalog, old_abdul, new_abdul, 'replace obsolete Abdul Basit direct-CDN key')

extra_arabic = '''  QuranAudioInfo(
    id: 'arabic_recitation_ibrahim_akhdar',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Ibrahim Akhdar',
    attribution: 'Islamic Network · Al Quran Cloud · 32 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.ibrahimakhbar',
    bitrate: 32,
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_parhizgar',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Parhizgar',
    attribution: 'Islamic Network · Al Quran Cloud · 48 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.parhizgar',
    bitrate: 48,
  ),
'''
catalog = replace_once(
    catalog,
    "  QuranAudioInfo(\n    id: 'english_rwwad_audio',",
    extra_arabic + "  QuranAudioInfo(\n    id: 'english_rwwad_audio',",
    'remaining Arabic audio editions',
)

russian_audio = '''  QuranAudioInfo(
    id: 'russian_kuliev_audio',
    sourceId: 'russian_kuliev',
    languageCode: 'ru',
    code: 'KUL-RU',
    title: 'Русский перевод · Эльмир Кулиев',
    attribution: 'Elmir Kuliev · Islamic Network · 128 kbps',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ru.kuliev-audio',
    bitrate: 128,
  ),
'''
catalog = replace_once(
    catalog,
    "  QuranAudioInfo(\n    id: 'tamil_omar_brief_audio',",
    russian_audio + "  QuranAudioInfo(\n    id: 'tamil_omar_brief_audio',",
    'Russian exact-source audio',
)
catalog_path.write_text(catalog, encoding='utf-8')

translation_path = Path('lib/src/data/translation_catalog.dart')
translations = translation_path.read_text(encoding='utf-8')
russian_text = '''  TranslationInfo(
    id: 'russian_kuliev',
    code: 'KUL-RU',
    languageCode: 'ru',
    name: 'Русский перевод · Эльмир Кулиев',
    publisher: 'Elmir Kuliev',
    source: 'Al Quran Cloud · Islamic Network',
    sourceKey: 'ru.kuliev',
    version: 'provider-current',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
    provider: TranslationProvider.islamicNetwork,
  ),
'''
translations = replace_once(
    translations,
    "  TranslationInfo(\n    id: 'russian_rwwad',",
    russian_text + "  TranslationInfo(\n    id: 'russian_rwwad',",
    'Russian Kuliev translation',
)
translation_path.write_text(translations, encoding='utf-8')

test_path = Path('test/audio_v2_catalog_test.dart')
tests = test_path.read_text(encoding='utf-8')
tests = replace_once(
    tests,
    "  test('selected bitrate changes URL and persistent storage identity', () {",
    "  test('direct CDN catalog does not keep obsolete Arabic aliases', () {\n    expect(quranAudioById('arabic_recitation_abdulbasit_mujawwad'), isNull);\n    expect(quranAudioById('arabic_recitation_abdul_samad')?.providerKey, 'ar.abdulsamad');\n    expect(quranAudioById('arabic_recitation_ibrahim_akhdar')?.providerKey, 'ar.ibrahimakhbar');\n    expect(quranAudioById('arabic_recitation_parhizgar')?.providerKey, 'ar.parhizgar');\n  });\n\n  test('Kuliev Russian audio is tied to Kuliev Russian text', () {\n    final audio = quranAudioById('russian_kuliev_audio');\n    final translation = translationById('russian_kuliev');\n    expect(audio?.sourceId, translation?.id);\n    expect(audio?.providerKey, 'ru.kuliev-audio');\n    expect(translation?.sourceKey, 'ru.kuliev');\n    expect(translation?.hasAudio, isTrue);\n  });\n\n  test('selected bitrate changes URL and persistent storage identity', () {",
    'final catalog tests',
)
test_path.write_text(tests, encoding='utf-8')

subprocess.run(['git', 'add', str(catalog_path), str(translation_path), str(test_path)], check=True)
subprocess.run(['git', 'commit', '-m', 'Finalize verified global human audio catalog'], check=True)
subprocess.run(['git', 'push', 'origin', 'HEAD:feature/localization-v01'], check=True)
