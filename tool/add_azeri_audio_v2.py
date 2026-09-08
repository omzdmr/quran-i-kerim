from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


path = Path('lib/src/data/quran_audio_catalog.dart')
text = path.read_text(encoding='utf-8')
needle = """  QuranAudioInfo(
    id: 'tagalog_rwwad_audio',
"""
entry = """  QuranAudioInfo(
    id: 'azeri_musayev_audio',
    sourceId: 'azeri_musayev',
    languageCode: 'az',
    code: 'MUS-AZ',
    title: 'Azərbaycan dilinə tərcümə',
    attribution: 'Əlixan Musayev · QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'azeri_musayev',
  ),
"""
text = replace_once(text, needle, entry + needle, 'Azeri spoken translation')
path.write_text(text, encoding='utf-8')

path = Path('lib/src/data/translation_catalog.dart')
text = path.read_text(encoding='utf-8')
old = """    sourceKey: 'azeri_musayev',
    version: '1.0.4',
    bundled: false,
    available: true,
    downloadable: true,
  ),
"""
new = """    sourceKey: 'azeri_musayev',
    version: '1.0.4',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
"""
text = replace_once(text, old, new, 'Azeri hasAudio flag')
path.write_text(text, encoding='utf-8')

path = Path('test/translation_catalog_test.dart')
text = path.read_text(encoding='utf-8')
old = """      expect(vakfi, isNotNull);
      expect(vakfi!.providerKey, 'tr.vakfi-audio');
      expect(hasQuranAudioForSource(bundledTurkishTranslationId), isFalse);
"""
new = """      expect(vakfi, isNotNull);
      expect(vakfi!.providerKey, 'tr.vakfi-audio');
      expect(
        primaryQuranAudioForSource('azeri_musayev')?.providerKey,
        'azeri_musayev',
      );
      expect(hasQuranAudioForSource(bundledTurkishTranslationId), isFalse);
"""
text = replace_once(text, old, new, 'Azeri audio test')
path.write_text(text, encoding='utf-8')
