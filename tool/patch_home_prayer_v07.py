from pathlib import Path

path = Path('lib/src/features/home/home_screen.dart')
text = path.read_text(encoding='utf-8')
original = text

old_import = "import '../../settings/app_settings.dart';\n"
new_import = old_import + "import 'home_prayer_card.dart';\n"
if "import 'home_prayer_card.dart';" not in text:
    if old_import not in text:
        raise SystemExit('home import marker not found')
    text = text.replace(old_import, new_import, 1)

old_block = """                      _ContinueCard(surah: lastSurah, ayah: settings.lastAyah),
                      const SizedBox(height: 18),
                      const _InfoCard(
"""
new_block = """                      _ContinueCard(surah: lastSurah, ayah: settings.lastAyah),
                      const SizedBox(height: 18),
                      const HomePrayerCard(),
                      const SizedBox(height: 18),
                      const _InfoCard(
"""
if 'const HomePrayerCard(),' not in text:
    if old_block not in text:
        raise SystemExit('home card insertion marker not found')
    text = text.replace(old_block, new_block, 1)

if text == original:
    print('Home prayer card already wired.')
else:
    path.write_text(text, encoding='utf-8')
    print('Home prayer card wired.')
