from pathlib import Path
import subprocess
import textwrap


def run(*args):
    subprocess.run(list(args), check=True)


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f'missing anchor: {label}')
    return text.replace(old, new, 1)


def write(path, content):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(textwrap.dedent(content).lstrip(), encoding='utf-8')


def validate():
    run('flutter', 'pub', 'get')
    run('flutter', 'analyze', 'lib', '--no-fatal-infos')
    run('flutter', 'test')


def commit(message, paths):
    run('git', 'add', *paths)
    run('git', 'commit', '-m', message)


reader_path = Path('lib/src/features/reader/quran_reader_screen.dart')
reader = reader_path.read_text(encoding='utf-8')

# ---------------------------------------------------------------------------
# Slice 1: local reading history + UI.
# ---------------------------------------------------------------------------
write('lib/src/features/reader/reader_reading_history.dart', r'''
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReaderHistoryEntry {
  const ReaderHistoryEntry({
    required this.surah,
    required this.ayah,
    required this.sourceId,
    required this.updatedAt,
  });

  final int surah;
  final int ayah;
  final String sourceId;
  final int updatedAt;

  Map<String, Object> toJson() => <String, Object>{
    'surah': surah,
    'ayah': ayah,
    'sourceId': sourceId,
    'updatedAt': updatedAt,
  };

  static ReaderHistoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final surah = value['surah'];
    final ayah = value['ayah'];
    final sourceId = value['sourceId'];
    final updatedAt = value['updatedAt'];
    if (surah is! num || ayah is! num || sourceId is! String || updatedAt is! num) {
      return null;
    }
    if (surah < 1 || surah > 114 || ayah < 1) return null;
    return ReaderHistoryEntry(
      surah: surah.toInt(),
      ayah: ayah.toInt(),
      sourceId: sourceId,
      updatedAt: updatedAt.toInt(),
    );
  }
}

class ReaderReadingHistoryRepository {
  ReaderReadingHistoryRepository._();

  static final ReaderReadingHistoryRepository instance =
      ReaderReadingHistoryRepository._();

  static const String storageKey = 'reader_history_v1';
  static const int maxEntries = 50;

  Future<List<ReaderHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const <ReaderHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ReaderHistoryEntry>[];
      return decoded
          .map(ReaderHistoryEntry.fromJson)
          .whereType<ReaderHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <ReaderHistoryEntry>[];
    }
  }

  Future<void> record({
    required int surah,
    required int ayah,
    required String sourceId,
  }) async {
    final safeSurah = surah.clamp(1, 114).toInt();
    final safeAyah = ayah < 1 ? 1 : ayah;
    final items = (await load()).toList(growable: true);
    items.removeWhere(
      (entry) => entry.surah == safeSurah && entry.ayah == safeAyah,
    );
    items.insert(
      0,
      ReaderHistoryEntry(
        surah: safeSurah,
        ayah: safeAyah,
        sourceId: sourceId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (items.length > maxEntries) {
      items.removeRange(maxEntries, items.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((entry) => entry.toJson()).toList(growable: false)),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
''')

write('test/reader_reading_history_test.dart', r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reading history keeps latest unique position first', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    await repo.record(surah: 2, ayah: 255, sourceId: 'arabic_original');
    await repo.record(surah: 36, ayah: 1, sourceId: 'arabic_original');
    await repo.record(surah: 2, ayah: 255, sourceId: 'tr_rwwad');

    final items = await repo.load();
    expect(items.length, 2);
    expect(items.first.surah, 2);
    expect(items.first.ayah, 255);
    expect(items.first.sourceId, 'tr_rwwad');
    expect(items[1].surah, 36);
  });

  test('reading history caps local history size', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    for (var i = 0; i < 60; i++) {
      await repo.record(surah: (i % 60) + 1, ayah: i + 1, sourceId: 'x');
    }
    expect((await repo.load()).length, ReaderReadingHistoryRepository.maxEntries);
  });
}
''')

reader = replace_once(
    reader,
    "import 'reader_note_sheet.dart';\n",
    "import 'reader_note_sheet.dart';\nimport 'reader_reading_history.dart';\n",
    'history import',
)

jump_anchor = """    if (save) {\n      AppSettingsScope.of(\n        context,\n      ).saveReadingPosition(surah: surah.number, ayah: safeAyah);\n    }\n    HapticFeedback.selectionClick();\n"""
jump_new = """    if (save) {\n      final settings = AppSettingsScope.of(context);\n      settings.saveReadingPosition(surah: surah.number, ayah: safeAyah);\n      ReaderReadingHistoryRepository.instance.record(\n        surah: surah.number,\n        ayah: safeAyah,\n        sourceId: settings.selectedQuranSourceId,\n      );\n    }\n    HapticFeedback.selectionClick();\n"""
reader = replace_once(reader, jump_anchor, jump_new, 'jump history')

open_anchor = """    AppSettingsScope.of(\n      context,\n    ).saveReadingPosition(surah: surah.number, ayah: 1);\n    HapticFeedback.selectionClick();\n"""
open_new = """    final settings = AppSettingsScope.of(context);\n    settings.saveReadingPosition(surah: surah.number, ayah: 1);\n    ReaderReadingHistoryRepository.instance.record(\n      surah: surah.number,\n      ayah: 1,\n      sourceId: settings.selectedQuranSourceId,\n    );\n    HapticFeedback.selectionClick();\n"""
reader = replace_once(reader, open_anchor, open_new, 'open surah history')

save_anchor = """    final settings = AppSettingsScope.of(context);\n    settings.saveReadingPosition(surah: _surahNumber, ayah: ayah);\n  }\n\n  Widget _segment"""
save_new = """    final settings = AppSettingsScope.of(context);\n    settings.saveReadingPosition(surah: _surahNumber, ayah: ayah);\n    ReaderReadingHistoryRepository.instance.record(\n      surah: _surahNumber,\n      ayah: ayah,\n      sourceId: settings.selectedQuranSourceId,\n    );\n  }\n\n  Widget _segment"""
reader = replace_once(reader, save_anchor, save_new, 'scroll history')

history_method = r'''
  Future<void> _showReadingHistory() async {
    final entries = await ReaderReadingHistoryRepository.instance.load();
    if (!mounted) return;
    final language = Localizations.localeOf(context).languageCode;
    final title = language == 'tr' ? 'Son okunanlar' : 'Reading history';
    final empty = language == 'tr'
        ? 'Henüz okuma geçmişi yok.'
        : 'No reading history yet.';
    final picked = await showModalBottomSheet<ReaderHistoryEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: SafeArea(
          child: entries.isEmpty
              ? Center(child: Text(empty))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final surah = surahByNumber(entry.surah);
                    final metadata = quranVerseMetadata(entry.surah, entry.ayah);
                    return ListTile(
                      leading: CircleAvatar(child: Text('${entry.surah}')),
                      title: Text('${_surahName(surah)} ${entry.surah}:${entry.ayah}'),
                      subtitle: Text(
                        language == 'tr'
                            ? 'Cüz ${metadata.juz} · Sayfa ${metadata.page}'
                            : 'Juz ${metadata.juz} · Page ${metadata.page}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(sheetContext, entry),
                    );
                  },
                ),
        ),
      ),
    );
    if (picked != null && mounted) {
      _jumpTo(picked.surah, picked.ayah);
    }
  }

'''
reader = replace_once(reader, '  void _showReaderMenu() {\n', history_method + '  void _showReaderMenu() {\n', 'history method')

history_tile = r'''
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Son okunanlar'
                      : 'Reading history',
                ),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Son okuduğun ayetlere dön'
                      : 'Return to recently read verses',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReadingHistory();
                },
              ),
'''
reader = replace_once(
    reader,
    "              ListTile(\n                leading: const Icon(Icons.verified_outlined),\n",
    history_tile + "              ListTile(\n                leading: const Icon(Icons.verified_outlined),\n",
    'history menu tile',
)
reader_path.write_text(reader, encoding='utf-8')

validate()
commit(
    'Add local Reader reading history',
    [
        'lib/src/features/reader/reader_reading_history.dart',
        'lib/src/features/reader/quran_reader_screen.dart',
        'test/reader_reading_history_test.dart',
    ],
)

# ---------------------------------------------------------------------------
# Slice 2: Surah/Juz/Page navigation + page/juz search.
# ---------------------------------------------------------------------------
write('lib/src/features/reader/reader_navigation.dart', r'''
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';

class ReaderNavigationTarget {
  const ReaderNavigationTarget({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}

ReaderNavigationTarget? firstVerseForPage(int page) {
  if (page < 1 || page > 604) return null;
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final value = quran.getPageNumber(surah.number, ayah);
      if (value == page) {
        return ReaderNavigationTarget(surah: surah.number, ayah: ayah);
      }
      if (value > page) return null;
    }
  }
  return null;
}

ReaderNavigationTarget? firstVerseForJuz(int juz) {
  if (juz < 1 || juz > 30) return null;
  for (final surah in surahCatalog) {
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      final value = quran.getJuzNumber(surah.number, ayah);
      if (value == juz) {
        return ReaderNavigationTarget(surah: surah.number, ayah: ayah);
      }
      if (value > juz) return null;
    }
  }
  return null;
}
''')

write('test/reader_navigation_test.dart', r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/reader/reader_navigation.dart';

void main() {
  test('page navigation resolves to a verse on the requested page', () {
    final first = firstVerseForPage(1);
    expect(first, isNotNull);
    expect(quran.getPageNumber(first!.surah, first.ayah), 1);

    final middle = firstVerseForPage(302);
    expect(middle, isNotNull);
    expect(quran.getPageNumber(middle!.surah, middle.ayah), 302);
  });

  test('juz navigation resolves to a verse in the requested juz', () {
    final target = firstVerseForJuz(15);
    expect(target, isNotNull);
    expect(quran.getJuzNumber(target!.surah, target.ayah), 15);
  });

  test('navigation rejects out of range values', () {
    expect(firstVerseForPage(0), isNull);
    expect(firstVerseForPage(605), isNull);
    expect(firstVerseForJuz(0), isNull);
    expect(firstVerseForJuz(31), isNull);
  });
}
''')

reader = reader_path.read_text(encoding='utf-8')
reader = replace_once(
    reader,
    "import 'reader_note_sheet.dart';\n",
    "import 'reader_navigation.dart';\nimport 'reader_note_sheet.dart';\n",
    'navigation import',
)
reader = replace_once(reader, "                                _showSurahs,\n", "                                _showReaderNavigator,\n", 'top navigator action')

navigator_methods = r'''
  Future<int?> _promptReaderNumber({
    required String title,
    required int max,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: '1-$max'),
          onSubmitted: (_) {
            final parsed = int.tryParse(controller.text);
            if (parsed != null && parsed >= 1 && parsed <= max) {
              Navigator.pop(dialogContext, parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed >= 1 && parsed <= max) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('Git'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _showReaderNavigator() async {
    final tr = Localizations.localeOf(context).languageCode == 'tr';
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: Text(tr ? 'Sure' : 'Surah'),
                subtitle: Text(tr ? '114 sure arasından seç' : 'Choose from 114 surahs'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, 'surah'),
              ),
              ListTile(
                leading: const Icon(Icons.view_agenda_outlined),
                title: Text(tr ? 'Cüz' : 'Juz'),
                subtitle: Text(tr ? '1-30 arasında cüze git' : 'Go to juz 1-30'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, 'juz'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(tr ? 'Sayfa' : 'Page'),
                subtitle: Text(tr ? '1-604 arasında sayfaya git' : 'Go to page 1-604'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, 'page'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'surah') {
      await _showSurahs();
      return;
    }
    if (choice == 'juz') {
      final value = await _promptReaderNumber(title: tr ? 'Cüze git' : 'Go to juz', max: 30);
      if (!mounted || value == null) return;
      final target = firstVerseForJuz(value);
      if (target != null) _jumpTo(target.surah, target.ayah);
      return;
    }
    final value = await _promptReaderNumber(title: tr ? 'Sayfaya git' : 'Go to page', max: 604);
    if (!mounted || value == null) return;
    final target = firstVerseForPage(value);
    if (target != null) _jumpTo(target.surah, target.ayah);
  }

'''
reader = replace_once(reader, '  Future<void> _showSurahs() async {\n', navigator_methods + '  Future<void> _showSurahs() async {\n', 'navigator methods')

search_anchor = """    for (final surah in surahCatalog) {\n"""
search_insert = r'''
    final pageMatch = RegExp(r'^(?:sayfa|page|p)\s*(\d{1,3})$').firstMatch(query);
    if (pageMatch != null) {
      final page = int.tryParse(pageMatch.group(1)!);
      if (page != null) {
        final target = firstVerseForPage(page);
        if (target != null) {
          final surah = surahByNumber(target.surah);
          addResult(
            _SearchResult(
              surah: target.surah,
              ayah: target.ayah,
              title: '${_surahName(surah)} ${target.surah}:${target.ayah}',
              subtitle: 'Sayfa $page · Page $page',
            ),
          );
        }
      }
    }

    final juzMatch = RegExp(r'^(?:cüz|cuz|juz)\s*(\d{1,2})$').firstMatch(query);
    if (juzMatch != null) {
      final juz = int.tryParse(juzMatch.group(1)!);
      if (juz != null) {
        final target = firstVerseForJuz(juz);
        if (target != null) {
          final surah = surahByNumber(target.surah);
          addResult(
            _SearchResult(
              surah: target.surah,
              ayah: target.ayah,
              title: '${_surahName(surah)} ${target.surah}:${target.ayah}',
              subtitle: 'Cüz $juz · Juz $juz',
            ),
          );
        }
      }
    }

'''
# Insert in _searchResults only, immediately before its first surah loop.
search_method_index = reader.index('  List<_SearchResult> _searchResults(')
loop_index = reader.index(search_anchor, search_method_index)
reader = reader[:loop_index] + search_insert + reader[loop_index:]
reader_path.write_text(reader, encoding='utf-8')

workflow_path = Path('.github/workflows/android.yml')
workflow = workflow_path.read_text(encoding='utf-8')
workflow = replace_once(
    workflow,
    '          test/reader_sleep_timer_test.dart\n          test/audio_v2_catalog_test.dart\n',
    '          test/reader_sleep_timer_test.dart\n          test/reader_reading_history_test.dart\n          test/reader_navigation_test.dart\n          test/audio_v2_catalog_test.dart\n',
    'android reader tests',
)
workflow_path.write_text(workflow, encoding='utf-8')

validate()
commit(
    'Add Surah Juz Page Reader navigation',
    [
        'lib/src/features/reader/reader_navigation.dart',
        'lib/src/features/reader/quran_reader_screen.dart',
        'test/reader_navigation_test.dart',
        '.github/workflows/android.yml',
    ],
)

# ---------------------------------------------------------------------------
# Slice 3: native share action for selected verses.
# ---------------------------------------------------------------------------
pubspec_path = Path('pubspec.yaml')
pubspec = pubspec_path.read_text(encoding='utf-8')
if '  share_plus:' not in pubspec:
    pubspec = replace_once(pubspec, '  quran: ^1.4.1\n', '  quran: ^1.4.1\n  share_plus: ^11.1.0\n', 'share dependency')
pubspec_path.write_text(pubspec, encoding='utf-8')

reader = reader_path.read_text(encoding='utf-8')
reader = replace_once(
    reader,
    "import 'package:quran/quran.dart' as quran;\n",
    "import 'package:quran/quran.dart' as quran;\nimport 'package:share_plus/share_plus.dart';\n",
    'share import',
)

share_method = r'''
  Future<void> _shareSelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    Map<String, String> translations = const <String, String>{};
    if (!settings.readerUsesArabic) {
      translations = await TranslationRepository.instance.loadSourceVerses(
        settings.selectedQuranSourceId,
      );
    }
    if (!mounted) return;
    final body = settings.readerUsesArabic
        ? selected.map((ayah) => quran.getVerse(_surahNumber, ayah)).join(' ')
        : selected
              .map((ayah) => translations['$_surahNumber:$ayah'])
              .whereType<String>()
              .join(' ');
    final reference = _selectionReference();
    final text = '$body\n\n$reference · ${_activeVersionCode(settings)}';
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: reference,
        title: reference,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (mounted) _clearSelection();
  }

'''
reader = replace_once(reader, '  Future<void> _showCompareSheet() async {\n', share_method + '  Future<void> _showCompareSheet() async {\n', 'share method')

tray_anchor = """                  child: _SelectionTray(\n                    onHighlight: _applyHighlight,\n                    onBookmark: _bookmarkSelection,\n                    onNote: _editSelectionNote,\n                    onListen: audioConfig == null\n                        ? null\n                        : () => _listenSelection(audioConfig),\n                    onCopy: _copySelection,\n                    onCompare: _showCompareSheet,\n                  ),\n"""
tray_new = """                  child: Row(\n                    children: [\n                      Expanded(\n                        child: _SelectionTray(\n                          onHighlight: _applyHighlight,\n                          onBookmark: _bookmarkSelection,\n                          onNote: _editSelectionNote,\n                          onListen: audioConfig == null\n                              ? null\n                              : () => _listenSelection(audioConfig),\n                          onCopy: _copySelection,\n                          onCompare: _showCompareSheet,\n                        ),\n                      ),\n                      const SizedBox(width: 6),\n                      Material(\n                        color: Theme.of(context).colorScheme.surfaceContainerHigh,\n                        borderRadius: BorderRadius.circular(22),\n                        child: IconButton(\n                          onPressed: _shareSelection,\n                          icon: const Icon(Icons.share_outlined),\n                          tooltip: Localizations.localeOf(context).languageCode == 'tr'\n                              ? 'Paylaş'\n                              : 'Share',\n                        ),\n                      ),\n                    ],\n                  ),\n"""
reader = replace_once(reader, tray_anchor, tray_new, 'share tray')
reader_path.write_text(reader, encoding='utf-8')

validate()
commit(
    'Add native verse sharing to Reader',
    ['pubspec.yaml', 'pubspec.lock', 'lib/src/features/reader/quran_reader_screen.dart'],
)

run('git', 'push', 'origin', 'HEAD:feature/localization-v01')
