from pathlib import Path
import re

path = Path('lib/src/features/reader/quran_reader_screen.dart')
text = path.read_text(encoding='utf-8')
original = text


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    text = text.replace(old, new, 1)


replace_once(
    """  @override
  void dispose() {
    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);
    _scrollController.dispose();
    super.dispose();
  }
""",
    """  @override
  void dispose() {
    AppNavigation.instance.setReaderSelectionActive(false);
    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);
    _scrollController.dispose();
    super.dispose();
  }
""",
    'dispose selection reset',
)

replace_once(
    """    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = safeAyah;
      _selectedAyahs.clear();
    });
    if (save) {
""",
    """    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = safeAyah;
      _selectedAyahs.clear();
    });
    AppNavigation.instance.setReaderSelectionActive(false);
    if (save) {
""",
    'jump selection reset',
)

replace_once(
    """    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = 1;
      _selectedAyahs.clear();
    });
    AppSettingsScope.of(context).saveReadingPosition(surah: surah.number, ayah: 1);
""",
    """    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = 1;
      _selectedAyahs.clear();
    });
    AppNavigation.instance.setReaderSelectionActive(false);
    AppSettingsScope.of(context).saveReadingPosition(surah: surah.number, ayah: 1);
""",
    'surah selection reset',
)

replace_once(
    """  void _toggleAyahSelection(int ayahNumber) {
    setState(() {
      if (!_selectedAyahs.add(ayahNumber)) {
        _selectedAyahs.remove(ayahNumber);
      }
    });
    HapticFeedback.selectionClick();
    AppSettingsScope.of(context).saveReadingPosition(
      surah: _surahNumber,
      ayah: ayahNumber,
    );
  }

  void _clearSelection() {
    if (_selectedAyahs.isEmpty) return;
    setState(_selectedAyahs.clear);
  }
""",
    """  void _toggleAyahSelection(int ayahNumber) {
    setState(() {
      if (!_selectedAyahs.add(ayahNumber)) {
        _selectedAyahs.remove(ayahNumber);
      }
    });
    AppNavigation.instance.setReaderSelectionActive(_selectedAyahs.isNotEmpty);
    HapticFeedback.selectionClick();
    AppSettingsScope.of(context).saveReadingPosition(
      surah: _surahNumber,
      ayah: ayahNumber,
    );
  }

  void _clearSelection() {
    if (_selectedAyahs.isEmpty) {
      AppNavigation.instance.setReaderSelectionActive(false);
      return;
    }
    setState(_selectedAyahs.clear);
    AppNavigation.instance.setReaderSelectionActive(false);
  }
""",
    'selection lifecycle',
)

pattern = re.compile(
    r"              Padding\(\n"
    r"                padding: const EdgeInsets\.fromLTRB\(16, 12, 10, 8\),\n"
    r"                child: Row\(\n"
    r".*?"
    r"              \),\n"
    r"              const Divider\(height: 1\),",
    re.S,
)
replacement = """              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                child: _selectedAyahs.isNotEmpty
                    ? Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Seçimi kapat',
                            ),
                            Expanded(
                              child: Text(
                                'Seçili: ${_selectionReference()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${_selectedAyahs.length}',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _segment(
                                      '${surah.nameTr} ${surah.number}',
                                      _showSurahs,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: scheme.outline.withValues(alpha: .28),
                                  ),
                                  SizedBox(
                                    width: 76,
                                    child: _segment(
                                      _activeVersionCode(settings),
                                      _showTranslations,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _showSearch,
                            icon: const Icon(Icons.search_rounded, size: 28),
                            tooltip: 'Kuran ve meal ara',
                          ),
                          IconButton(
                            onPressed: _showReaderMenu,
                            icon: const Icon(Icons.more_horiz_rounded, size: 29),
                            tooltip: 'Okuma ayarları',
                          ),
                        ],
                      ),
              ),
              const Divider(height: 1),"""
text, count = pattern.subn(replacement, text, count=1)
if count != 1:
    raise SystemExit(f'top selection toolbar: expected 1 match, found {count}')

replace_once('            bottom: 76,', '            bottom: 8,', 'selection tray bottom')

replace_once(
    """                  child: _SelectionTray(
                    reference: _selectionReference(),
                    count: _selectedAyahs.length,
                    onClose: _clearSelection,
                    onHighlight: _chooseHighlight,
                    onBookmark: _bookmarkSelection,
                    onNote: _editSelectionNote,
                    onCopy: _copySelection,
                    onCompare: _showCompareSheet,
                  ),
""",
    """                  child: _SelectionTray(
                    onHighlight: _applyHighlight,
                    onBookmark: _bookmarkSelection,
                    onNote: _editSelectionNote,
                    onCopy: _copySelection,
                    onCompare: _showCompareSheet,
                  ),
""",
    'selection tray call',
)

replace_once(
    '        padding: const EdgeInsets.fromLTRB(22, 28, 22, 118),',
    '        padding: EdgeInsets.fromLTRB(22, 28, 22, _selectedAyahs.isEmpty ? 118 : 78),',
    'reader bottom padding',
)

highlight_pattern = re.compile(
    r"  Future<void> _chooseHighlight\(\) async \{.*?\n  \}\n\n  Future<void> _bookmarkSelection",
    re.S,
)
highlight_replacement = """  Future<void> _applyHighlight(VerseHighlightColor? color) async {
    final selected = _selection;
    if (selected.isEmpty) return;
    await AppSettingsScope.of(context).setHighlightForSelection(
      _surahNumber,
      selected,
      color,
    );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _clearSelection();
  }

  Future<void> _bookmarkSelection"""
text, count = highlight_pattern.subn(highlight_replacement, text, count=1)
if count != 1:
    raise SystemExit(f'direct highlight action: expected 1 match, found {count}')

tray_pattern = re.compile(
    r"class _SelectionTray extends StatelessWidget \{.*?\n\}\n\nclass _SelectionAction",
    re.S,
)
tray_replacement = """class _SelectionTray extends StatelessWidget {
  const _SelectionTray({
    required this.onHighlight,
    required this.onBookmark,
    required this.onNote,
    required this.onCopy,
    required this.onCompare,
  });

  final ValueChanged<VerseHighlightColor?> onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(26),
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 70,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              for (final color in VerseHighlightColor.values)
                _HighlightDot(
                  color: color,
                  onTap: () => onHighlight(color),
                ),
              IconButton(
                onPressed: () => onHighlight(null),
                icon: const Icon(Icons.format_color_reset_rounded, size: 20),
                tooltip: 'Vurguyu kaldır',
              ),
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color: scheme.outlineVariant,
              ),
              _SelectionAction(
                icon: Icons.bookmark_border_rounded,
                label: 'Kaydet',
                onTap: onBookmark,
              ),
              _SelectionAction(
                icon: Icons.note_alt_outlined,
                label: 'Not',
                onTap: onNote,
              ),
              _SelectionAction(
                icon: Icons.copy_rounded,
                label: 'Kopyala',
                onTap: onCopy,
              ),
              _SelectionAction(
                icon: Icons.compare_arrows_rounded,
                label: 'Karşılaştır',
                onTap: onCompare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionAction"""
text, count = tray_pattern.subn(tray_replacement, text, count=1)
if count != 1:
    raise SystemExit(f'compact selection tray: expected 1 match, found {count}')

replace_once(
    """        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            width: 44,
            height: 44,
""",
    """        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: 32,
            height: 32,
""",
    'compact highlight dots',
)

if text == original:
    raise SystemExit('No changes were made')

path.write_text(text, encoding='utf-8')
print('Reader selection UX patched successfully.')
