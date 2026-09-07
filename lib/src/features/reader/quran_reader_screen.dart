import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../settings/app_settings.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  int _surahNumber = 1;
  bool _didRestorePosition = false;
  final Set<int> _selectedAyahs = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestorePosition) return;
    _surahNumber = AppSettingsScope.of(context).lastSurah;
    _didRestorePosition = true;
  }

  List<int> get _selection {
    final values = _selectedAyahs.toList()..sort();
    return values;
  }

  String _selectionReference() {
    final surah = surahByNumber(_surahNumber);
    final values = _selection;
    if (values.isEmpty) return '${surah.nameTr} $_surahNumber';
    if (values.length == 1) {
      return '${surah.nameTr} $_surahNumber:${values.single}';
    }

    var contiguous = true;
    for (var i = 1; i < values.length; i++) {
      if (values[i] != values[i - 1] + 1) {
        contiguous = false;
        break;
      }
    }

    final ayahPart = contiguous
        ? '${values.first}-${values.last}'
        : values.join(',');
    return '${surah.nameTr} $_surahNumber:$ayahPart';
  }

  void _toggleAyahSelection(int ayahNumber) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surah = surahByNumber(_surahNumber);
    final settings = AppSettingsScope.of(context);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 15, 10),
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _segment('${surah.nameTr} ${surah.number}', _showSurahs),
                            Container(
                              width: 1,
                              height: 48,
                              color: scheme.outline.withValues(alpha: .28),
                            ),
                            _segment('AR', _showTranslations),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showSurahs,
                      icon: const Icon(Icons.search_rounded, size: 29),
                      tooltip: 'Sure ara',
                    ),
                    IconButton(
                      onPressed: _showReaderMenu,
                      icon: const Icon(Icons.more_horiz_rounded, size: 30),
                      tooltip: 'Okuma ayarları',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  key: ValueKey(_surahNumber),
                  padding: EdgeInsets.fromLTRB(
                    26,
                    40,
                    26,
                    _selectedAyahs.isEmpty ? 140 : 260,
                  ),
                  itemCount: surah.verseCount + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _surahHeader(surah);
                    return _Verse(
                      surahNumber: _surahNumber,
                      ayahNumber: index,
                      arabic: quran.getVerse(_surahNumber, index),
                      arabicFontSize: settings.arabicFontSize,
                      bookmarked: settings.isBookmarked(_surahNumber, index),
                      hasNote: settings.noteFor(_surahNumber, index)?.isNotEmpty ?? false,
                      highlight: settings.highlightFor(_surahNumber, index),
                      selected: _selectedAyahs.contains(index),
                      onTap: () => _toggleAyahSelection(index),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 86,
            child: IgnorePointer(
              ignoring: _selectedAyahs.isEmpty,
              child: AnimatedSlide(
                offset: _selectedAyahs.isEmpty
                    ? const Offset(0, 1.35)
                    : Offset.zero,
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _selectedAyahs.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 170),
                  child: _SelectionTray(
                    reference: _selectionReference(),
                    count: _selectedAyahs.length,
                    onClose: _clearSelection,
                    onHighlight: _chooseHighlight,
                    onBookmark: _bookmarkSelection,
                    onNote: _editSelectionNote,
                    onCopy: _copySelection,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
          ),
        ),
      );

  Widget _surahHeader(SurahInfo surah) {
    final scheme = Theme.of(context).colorScheme;
    final hasSeparateBasmala = surah.number != 1 && surah.number != 9;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Text(
            surah.nameTr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontSize: 34,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            surah.nameAr,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 23,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${surah.verseCount} ayet',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasSeparateBasmala) ...[
            const SizedBox(height: 34),
            Text(
              quran.basmala,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 25,
                height: 1.9,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showReaderMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: const Text('Yazı tipi ve okuma görünümü'),
                subtitle: const Text('Arapça boyutu ve görünüm ayarları'),
                onTap: () {
                  Navigator.pop(context);
                  _showReadingAppearance();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Meal seç'),
                subtitle: const Text('İlk Türkçe meal paketi hazırlanıyor'),
                onTap: () {
                  Navigator.pop(context);
                  _showTranslations();
                },
              ),
              const ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('Arapça metin kaynağı'),
                subtitle: Text('Tanzil.net · çevrimdışı ve değiştirilmeden'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReadingAppearance() async {
    final settings = AppSettingsScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Okuma görünümü',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Arapça yazı boyutu',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(settings.arabicFontSize.round().toString()),
                  ],
                ),
                Slider(
                  min: 22,
                  max: 42,
                  divisions: 20,
                  value: settings.arabicFontSize,
                  onChanged: (value) {
                    settings.setArabicFontSize(value);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                const _ModePreview(
                  title: 'Arapça',
                  subtitle: 'Şu an aktif',
                  selected: true,
                ),
                const _ModePreview(
                  title: 'Arapça + meal',
                  subtitle: 'Türkçe meal paketi eklenince açılacak',
                ),
                const _ModePreview(
                  title: 'Sadece meal',
                  subtitle: 'Türkçe meal paketi eklenince açılacak',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSurahs() async {
    final controller = TextEditingController();
    String query = '';

    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .92,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final normalized = query.trim().toLowerCase();
              final filtered = normalized.isEmpty
                  ? surahCatalog
                  : surahCatalog.where((surah) {
                      return surah.nameTr.toLowerCase().contains(normalized) ||
                          surah.nameAr.contains(normalized) ||
                          surah.number.toString() == normalized;
                    }).toList(growable: false);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                        const Expanded(
                          child: Text(
                            'Sureler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                    child: TextField(
                      controller: controller,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Sure adı veya numara ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  controller.clear();
                                  setSheetState(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final surah = filtered[index];
                        return _SurahRow(
                          surah: surah,
                          selected: surah.number == _surahNumber,
                          onTap: () => Navigator.pop(sheetContext, surah.number),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    controller.dispose();
    if (picked == null || !mounted) return;
    setState(() {
      _surahNumber = picked;
      _selectedAyahs.clear();
    });
    await AppSettingsScope.of(context).saveReadingPosition(
      surah: picked,
      ayah: 1,
    );
  }

  Future<void> _showTranslations() async {
    final scheme = Theme.of(context).colorScheme;
    final candidate = translationCatalog.first;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mealler',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${candidate.code} · ${candidate.name}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${candidate.publisher} · ${candidate.source} · v${candidate.version}',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.schedule_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Meal metnini lisans ve sürüm bilgisiyle birlikte paketliyoruz. Hazır olmadan başka bir metni Diyanet diye göstermeyeceğiz.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseHighlight() async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;

    final picked = await showModalBottomSheet<VerseHighlightColor?>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vurgu rengi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                _selectionReference(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final color in VerseHighlightColor.values)
                    _HighlightDot(
                      color: color,
                      onTap: () => Navigator.pop(sheetContext, color),
                    ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.format_color_reset_rounded),
                    tooltip: 'Vurguyu kaldır',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    // null, alt sayfanın kapatılması veya "vurguyu kaldır" anlamına gelebileceği
    // için kaldırma işlemini ayrı bir menüye bırakıyoruz. Renk seçildiyse uygula.
    if (picked != null) {
      await settings.setHighlightForSelection(_surahNumber, selected, picked);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _bookmarkSelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    await AppSettingsScope.of(context).bookmarkSelection(_surahNumber, selected);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? 'Ayet kaydedildi'
              : '${selected.length} ayet kaydedildi',
        ),
      ),
    );
  }

  Future<void> _copySelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;

    final verses = selected
        .map((ayah) => quran.getVerse(_surahNumber, ayah))
        .join('\n');
    final text = '$verses\n\n${_selectionReference()}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? 'Ayet kopyalandı'
              : '${selected.length} ayet kopyalandı',
        ),
      ),
    );
  }

  Future<void> _editSelectionNote() async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;

    final controller = TextEditingController(
      text: settings.noteForSelection(_surahNumber, selected) ?? '',
    );
    final verses = selected
        .map((ayah) => quran.getVerse(_surahNumber, ayah))
        .join('\n');

    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: .94,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Not',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, controller.text),
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Ne söylemek istersiniz?',
                    filled: true,
                    fillColor: scheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectionReference(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        verses,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 25,
                          height: 1.9,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notunuz yalnızca bu cihazda saklanır.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    if (value != null) {
      await settings.setNoteForSelection(_surahNumber, selected, value);
      if (mounted) HapticFeedback.lightImpact();
    }
  }
}

class _Verse extends StatelessWidget {
  const _Verse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.arabicFontSize,
    required this.bookmarked,
    required this.hasNote,
    required this.highlight,
    required this.selected,
    required this.onTap,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final double arabicFontSize;
  final bool bookmarked;
  final bool hasNote;
  final VerseHighlightColor? highlight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlightColor = highlight == null
        ? Colors.transparent
        : _highlightMaterialColor(highlight!).withValues(alpha: .22);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: .52)
            : highlightColor,
        borderRadius: BorderRadius.circular(18),
        border: selected
            ? Border.all(color: scheme.primary.withValues(alpha: .62))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: arabicFontSize,
                  height: 2.02,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  if (selected && (bookmarked || hasNote))
                    const SizedBox(width: 6),
                  if (bookmarked)
                    Icon(
                      Icons.bookmark_rounded,
                      size: 17,
                      color: scheme.primary,
                    ),
                  if (bookmarked && hasNote) const SizedBox(width: 5),
                  if (hasNote)
                    Icon(
                      Icons.note_alt_rounded,
                      size: 17,
                      color: scheme.primary,
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer.withValues(alpha: .86),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$surahNumber:$ayahNumber',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionTray extends StatelessWidget {
  const _SelectionTray({
    required this.reference,
    required this.count,
    required this.onClose,
    required this.onHighlight,
    required this.onBookmark,
    required this.onNote,
    required this.onCopy,
  });

  final String reference;
  final int count;
  final VoidCallback onClose;
  final VoidCallback onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(28),
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Seçimi kapat',
                ),
                Expanded(
                  child: Text(
                    'Seçili: $reference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SelectionAction(
                    icon: Icons.palette_outlined,
                    label: 'Renk',
                    onTap: onHighlight,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionAction extends StatefulWidget {
  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SelectionAction> createState() => _SelectionActionState();
}

class _SelectionActionState extends State<_SelectionAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .93 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 82,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 22),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightDot extends StatelessWidget {
  const _HighlightDot({required this.color, required this.onTap});

  final VerseHighlightColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _highlightMaterialColor(color),
            ),
          ),
        ),
      );
}

Color _highlightMaterialColor(VerseHighlightColor color) => switch (color) {
      VerseHighlightColor.yellow => const Color(0xFFFFD84D),
      VerseHighlightColor.green => const Color(0xFF65D996),
      VerseHighlightColor.blue => const Color(0xFF68B7F5),
      VerseHighlightColor.orange => const Color(0xFFFFB86A),
      VerseHighlightColor.pink => const Color(0xFFF08BCB),
    };

class _ModePreview extends StatelessWidget {
  const _ModePreview({
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.selected,
    required this.onTap,
  });

  final SurahInfo surah;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        leading: SizedBox(
          width: 34,
          child: Text(
            '${surah.number}',
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          surah.nameTr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${surah.verseCount} ayet'),
        trailing: Text(
          surah.nameAr,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'serif', fontSize: 20),
        ),
      ),
    );
  }
}
