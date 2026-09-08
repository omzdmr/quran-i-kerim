import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  int _surahNumber = 1;
  int _anchorAyah = 0;
  bool _didRestorePosition = false;
  Key _centerKey = UniqueKey();
  final Set<int> _selectedAyahs = <int>{};
  late final Future<Map<String, String>> _turkishTranslation;

  @override
  void initState() {
    super.initState();
    _turkishTranslation = TranslationRepository.instance.loadBundledTurkish();
    AppNavigation.instance.readerRequest.addListener(_handleReaderRequest);
  }

  @override
  void dispose() {
    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestorePosition) return;
    final settings = AppSettingsScope.of(context);
    _surahNumber = settings.lastSurah;
    final surah = surahByNumber(_surahNumber);
    _anchorAyah = settings.lastAyah.clamp(1, surah.verseCount).toInt();
    _centerKey = UniqueKey();
    _didRestorePosition = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleReaderRequest());
  }

  void _handleReaderRequest() {
    if (!mounted || !_didRestorePosition) return;
    final target = AppNavigation.instance.readerRequest.value;
    if (target == null) return;
    _jumpTo(target.surah, target.ayah);
    AppNavigation.instance.consumeReaderRequest();
  }

  void _jumpTo(int surahNumber, int ayah, {bool save = true}) {
    final surah = surahByNumber(surahNumber.clamp(1, 114).toInt());
    final safeAyah = ayah.clamp(1, surah.verseCount).toInt();
    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = safeAyah;
      _selectedAyahs.clear();
      _centerKey = UniqueKey();
    });
    if (save) {
      AppSettingsScope.of(context).saveReadingPosition(
        surah: surah.number,
        ayah: safeAyah,
      );
    }
    HapticFeedback.selectionClick();
  }

  void _openSurahAtStart(int surahNumber) {
    final surah = surahByNumber(surahNumber);
    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = 0;
      _selectedAyahs.clear();
      _centerKey = UniqueKey();
    });
    AppSettingsScope.of(context).saveReadingPosition(surah: surah.number, ayah: 1);
    HapticFeedback.selectionClick();
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

  String _activeVersionCode(AppSettings settings) => switch (settings.readerMode) {
        ReaderDisplayMode.arabic => 'AR',
        ReaderDisplayMode.translation => translationCatalog.first.code,
        ReaderDisplayMode.arabicAndTranslation => 'AR+${translationCatalog.first.code}',
      };

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
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                child: Row(
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
                              width: 78,
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
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<Map<String, String>>(
                  future: _turkishTranslation,
                  builder: (context, snapshot) {
                    final translations = snapshot.data ?? const <String, String>{};
                    return _readerScrollView(
                      surah: surah,
                      settings: settings,
                      translations: translations,
                      translationError: snapshot.hasError,
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 78,
            child: IgnorePointer(
              ignoring: _selectedAyahs.isEmpty,
              child: AnimatedSlide(
                offset: _selectedAyahs.isEmpty
                    ? const Offset(0, 1.25)
                    : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _selectedAyahs.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: _SelectionTray(
                    reference: _selectionReference(),
                    count: _selectedAyahs.length,
                    onClose: _clearSelection,
                    onHighlight: _chooseHighlight,
                    onBookmark: _bookmarkSelection,
                    onNote: _editSelectionNote,
                    onCopy: _copySelection,
                    onCompare: _showCompareSheet,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readerScrollView({
    required SurahInfo surah,
    required AppSettings settings,
    required Map<String, String> translations,
    required bool translationError,
  }) {
    final anchor = _anchorAyah.clamp(0, surah.verseCount).toInt();
    final bottomPadding = _selectedAyahs.isEmpty ? 132.0 : 184.0;

    Widget verse(int ayah) => _Verse(
          surahNumber: _surahNumber,
          ayahNumber: ayah,
          arabic: quran.getVerse(_surahNumber, ayah),
          translation: translations['$_surahNumber:$ayah'],
          mode: settings.readerMode,
          arabicFontSize: settings.arabicFontSize,
          translationFontSize: settings.translationFontSize,
          arabicLineHeight: settings.arabicLineHeight,
          translationLineHeight: settings.translationLineHeight,
          bookmarked: settings.isBookmarked(_surahNumber, ayah),
          hasNote: settings.noteFor(_surahNumber, ayah)?.isNotEmpty ?? false,
          highlight: settings.highlightFor(_surahNumber, ayah),
          selected: _selectedAyahs.contains(ayah),
          onTap: () => _toggleAyahSelection(ayah),
        );

    Widget header() => Column(
          children: [
            _surahHeader(surah, settings),
            if (translationError && settings.readerMode != ReaderDisplayMode.arabic)
              _TranslationError(onRetry: () => setState(() {})),
          ],
        );

    final beforeCount = anchor == 0 ? 0 : anchor;
    final centerCount = anchor == 0
        ? surah.verseCount + 1
        : surah.verseCount - anchor + 1;

    return CustomScrollView(
      key: ValueKey((_surahNumber, anchor, settings.readerMode)),
      center: _centerKey,
      anchor: anchor == 0 ? 0 : .06,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) return header();
                return verse(index);
              },
              childCount: beforeCount,
            ),
          ),
        ),
        SliverPadding(
          key: _centerKey,
          padding: EdgeInsets.fromLTRB(
            22,
            anchor == 0 ? 34 : 18,
            22,
            bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (anchor == 0) {
                  if (index == 0) return header();
                  return verse(index);
                }
                return verse(anchor + index);
              },
              childCount: centerCount,
            ),
          ),
        ),
      ],
    );
  }

  Widget _segment(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );

  Widget _surahHeader(SurahInfo surah, AppSettings settings) {
    final scheme = Theme.of(context).colorScheme;
    final hasSeparateBasmala = surah.number != 1 && surah.number != 9;
    final showArabicHeader = settings.readerMode != ReaderDisplayMode.translation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Text(
            surah.nameTr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontSize: 32,
                ),
          ),
          if (showArabicHeader) ...[
            const SizedBox(height: 4),
            Text(
              surah.nameAr,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${surah.verseCount} ayet',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasSeparateBasmala && showArabicHeader) ...[
            const SizedBox(height: 28),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showReaderMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: const Text('Yazı tipi ve okuma görünümü'),
                subtitle: const Text('Yazı boyutu ve satır aralığı'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReadingAppearance();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Okuma metni'),
                subtitle: Text('${_activeVersionCode(AppSettingsScope.of(context))} · çevrimdışı'),
                onTap: () {
                  Navigator.pop(sheetContext);
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
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                const Text(
                  'Okuma görünümü',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                _FontSizeControl(
                  title: 'Arapça',
                  value: settings.arabicFontSize.round(),
                  preview: 'بِسْمِ اللَّهِ',
                  onDecrease: () {
                    settings.setArabicFontSize(settings.arabicFontSize - 2);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                  onIncrease: () {
                    settings.setArabicFontSize(settings.arabicFontSize + 2);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _FontSizeControl(
                  title: 'Meal',
                  value: settings.translationFontSize.round(),
                  preview: 'Türkçe meal',
                  onDecrease: () {
                    settings.setTranslationFontSize(settings.translationFontSize - 1.5);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                  onIncrease: () {
                    settings.setTranslationFontSize(settings.translationFontSize + 1.5);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 20),
                const Text('Satır aralığı', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in ReaderLineSpacing.values)
                      ChoiceChip(
                        label: Text(switch (option) {
                          ReaderLineSpacing.compact => 'Sık',
                          ReaderLineSpacing.normal => 'Normal',
                          ReaderLineSpacing.relaxed => 'Ferah',
                        }),
                        selected: settings.readerLineSpacing == option,
                        onSelected: (_) {
                          settings.setReaderLineSpacing(option);
                          HapticFeedback.selectionClick();
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Ana okuyucuda tek metin gösterilir. Farklı mealleri veya Arapçayı yan yana görmek için ayet seçip Karşılaştır’ı kullanın.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSearch() async {
    final translations = await _turkishTranslation;
    if (!mounted) return;
    final controller = TextEditingController();
    String query = '';

    final picked = await showModalBottomSheet<_SearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .94,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final results = _searchResults(query, translations);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Kuran’da ara',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Bakara, 2:255 veya sabır ara',
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
                    child: query.trim().isEmpty
                        ? const _SearchHint()
                        : results.isEmpty
                            ? const Center(child: Text('Sonuç bulunamadı.'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                                itemCount: results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final result = results[index];
                                  return _SearchResultTile(
                                    result: result,
                                    onTap: () => Navigator.pop(sheetContext, result),
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
    _jumpTo(picked.surah, picked.ayah);
  }

  List<_SearchResult> _searchResults(
    String rawQuery,
    Map<String, String> translations,
  ) {
    final query = _normalizeSearch(rawQuery);
    if (query.isEmpty) return const <_SearchResult>[];
    final results = <_SearchResult>[];
    final seen = <String>{};

    void addResult(_SearchResult result) {
      final key = '${result.surah}:${result.ayah}';
      if (seen.add(key)) results.add(result);
    }

    final numeric = RegExp(r'^(\d{1,3})\s*[:/.\- ]\s*(\d{1,3})$').firstMatch(query);
    if (numeric != null) {
      final surahNumber = int.tryParse(numeric.group(1)!);
      final ayah = int.tryParse(numeric.group(2)!);
      if (surahNumber != null && ayah != null && surahNumber >= 1 && surahNumber <= 114) {
        final surah = surahByNumber(surahNumber);
        if (ayah >= 1 && ayah <= surah.verseCount) {
          addResult(_SearchResult(
            surah: surahNumber,
            ayah: ayah,
            title: '${surah.nameTr} $surahNumber:$ayah',
            subtitle: translations['$surahNumber:$ayah'] ?? '',
          ));
        }
      }
    }

    for (final surah in surahCatalog) {
      final normalizedName = _normalizeSearch(surah.nameTr);
      if (normalizedName.contains(query) || _normalizeSearch(surah.nameAr).contains(query)) {
        addResult(_SearchResult(
          surah: surah.number,
          ayah: 1,
          title: '${surah.nameTr} · ${surah.verseCount} ayet',
          subtitle: surah.nameAr,
          isSurah: true,
        ));
      }
      if (query.startsWith('$normalizedName ')) {
        final possibleAyah = int.tryParse(query.substring(normalizedName.length).trim());
        if (possibleAyah != null && possibleAyah >= 1 && possibleAyah <= surah.verseCount) {
          addResult(_SearchResult(
            surah: surah.number,
            ayah: possibleAyah,
            title: '${surah.nameTr} ${surah.number}:$possibleAyah',
            subtitle: translations['${surah.number}:$possibleAyah'] ?? '',
          ));
        }
      }
    }

    if (query.length >= 2) {
      for (final entry in translations.entries) {
        if (results.length >= 60) break;
        if (!_normalizeSearch(entry.value).contains(query)) continue;
        final parts = entry.key.split(':');
        if (parts.length != 2) continue;
        final surahNumber = int.tryParse(parts[0]);
        final ayah = int.tryParse(parts[1]);
        if (surahNumber == null || ayah == null || surahNumber < 1 || surahNumber > 114) {
          continue;
        }
        final surah = surahByNumber(surahNumber);
        addResult(_SearchResult(
          surah: surahNumber,
          ayah: ayah,
          title: '${surah.nameTr} $surahNumber:$ayah',
          subtitle: entry.value,
        ));
      }
    }

    return results.take(60).toList(growable: false);
  }

  String _normalizeSearch(String value) => value
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase();

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
    _openSurahAtStart(picked);
  }

  Future<void> _showTranslations() async {
    final settings = AppSettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final candidate = translationCatalog.first;

    final picked = await showModalBottomSheet<ReaderDisplayMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Okuma metni',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Ana okuyucuda tek metin seçin. Karşılaştırma ayrı ekranda açılır.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _VersionChoice(
                code: candidate.code,
                title: 'Türkçe Tercüme',
                subtitle: '${candidate.publisher} · çevrimdışı',
                selected: settings.readerMode == ReaderDisplayMode.translation,
                onTap: () => Navigator.pop(sheetContext, ReaderDisplayMode.translation),
              ),
              const SizedBox(height: 8),
              _VersionChoice(
                code: 'AR',
                title: 'Arapça · Orijinal Kuran metni',
                subtitle: 'Tanzil.net · çevrimdışı',
                selected: settings.readerMode == ReaderDisplayMode.arabic,
                onTap: () => Navigator.pop(sheetContext, ReaderDisplayMode.arabic),
              ),
              const SizedBox(height: 12),
              Text(
                'Yeni mealler ve diller indirildikçe burada listelenecek.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    await settings.setReaderMode(picked);
    HapticFeedback.selectionClick();
  }

  Future<void> _chooseHighlight() async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;

    final picked = await showModalBottomSheet<Object?>(
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
                    onPressed: () => Navigator.pop(sheetContext, 'clear'),
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

    if (!mounted || picked == null) return;
    if (picked == 'clear') {
      await settings.setHighlightForSelection(_surahNumber, selected, null);
    } else if (picked is VerseHighlightColor) {
      await settings.setHighlightForSelection(_surahNumber, selected, picked);
    }
    HapticFeedback.lightImpact();
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
              : '${_selectionReference()} tek kayıt olarak kaydedildi',
        ),
      ),
    );
  }

  Future<void> _copySelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    final translations = await _turkishTranslation;

    final arabic = selected
        .map((ayah) => quran.getVerse(_surahNumber, ayah))
        .join('\n');
    final meal = selected
        .map((ayah) => translations['$_surahNumber:$ayah'])
        .whereType<String>()
        .join('\n');

    final body = switch (settings.readerMode) {
      ReaderDisplayMode.arabic => arabic,
      ReaderDisplayMode.translation => meal,
      ReaderDisplayMode.arabicAndTranslation => '$arabic\n\n$meal',
    };
    final text = '$body\n\n${_selectionReference()} · ${_activeVersionCode(settings)}';

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

  Future<void> _showCompareSheet() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final translations = await _turkishTranslation;
    if (!mounted) return;
    final settings = AppSettingsScope.of(context);
    final currentIsArabic = settings.readerMode == ReaderDisplayMode.arabic;
    var showOther = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final rwdText = selected
                .map((ayah) => translations['$_surahNumber:$ayah'])
                .whereType<String>()
                .join(' ');
            final arabicText = selected
                .map((ayah) => quran.getVerse(_surahNumber, ayah))
                .join(' ');

            Widget versionBlock({
              required String code,
              required String title,
              required String text,
              required bool arabic,
            }) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          code,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      text,
                      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: arabic ? 'serif' : null,
                        fontSize: arabic ? 27 : 23,
                        height: arabic ? 1.9 : 1.55,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Versiyonları Karşılaştır',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              _selectionReference(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      if (currentIsArabic)
                        versionBlock(
                          code: 'AR',
                          title: 'Arapça · Orijinal Kuran metni',
                          text: arabicText,
                          arabic: true,
                        )
                      else
                        versionBlock(
                          code: translationCatalog.first.code,
                          title: 'Türkçe Tercüme',
                          text: rwdText,
                          arabic: false,
                        ),
                      if (showOther) ...[
                        const Divider(height: 1),
                        if (currentIsArabic)
                          versionBlock(
                            code: translationCatalog.first.code,
                            title: 'Türkçe Tercüme',
                            text: rwdText,
                            arabic: false,
                          )
                        else
                          versionBlock(
                            code: 'AR',
                            title: 'Arapça · Orijinal Kuran metni',
                            text: arabicText,
                            arabic: true,
                          ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: showOther
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setSheetState(() => showOther = true);
                              },
                        icon: const Icon(Icons.add_rounded, size: 30),
                        label: Text(showOther ? 'Ek versiyon gösteriliyor' : 'Versiyon Ekle'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editSelectionNote() async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;
    final translations = await _turkishTranslation;

    final controller = TextEditingController(
      text: settings.noteForSelection(_surahNumber, selected) ?? '',
    );
    final arabic = selected
        .map((ayah) => quran.getVerse(_surahNumber, ayah))
        .join('\n');
    final meal = selected
        .map((ayah) => translations['$_surahNumber:$ayah'])
        .whereType<String>()
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, controller.text),
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
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_selectionReference()} · ${_activeVersionCode(settings)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (settings.readerMode != ReaderDisplayMode.translation)
                            Text(
                              arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 24,
                                height: 1.9,
                              ),
                            ),
                          if (settings.readerMode != ReaderDisplayMode.arabic && meal.isNotEmpty)
                            Text(
                              meal,
                              style: const TextStyle(fontSize: 17, height: 1.55),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
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
    required this.translation,
    required this.mode,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.arabicLineHeight,
    required this.translationLineHeight,
    required this.bookmarked,
    required this.hasNote,
    required this.highlight,
    required this.selected,
    required this.onTap,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String? translation;
  final ReaderDisplayMode mode;
  final double arabicFontSize;
  final double translationFontSize;
  final double arabicLineHeight;
  final double translationLineHeight;
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
        : _highlightMaterialColor(highlight!).withValues(alpha: .30);
    final showArabic = mode != ReaderDisplayMode.translation;
    final showTranslation = mode != ReaderDisplayMode.arabic;

    TextSpan numberSpan({required bool arabicDirection}) => TextSpan(
          text: arabicDirection ? '  $ayahNumber' : '$ayahNumber  ',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: arabicDirection ? 13 : 12,
            fontWeight: FontWeight.w700,
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: highlightColor,
        border: Border(
          bottom: BorderSide(
            color: selected ? scheme.primary : Colors.transparent,
            width: selected ? 2.2 : 0,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showArabic)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: arabic,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: arabicFontSize,
                        height: arabicLineHeight,
                        color: scheme.onSurface,
                      ),
                    ),
                    numberSpan(arabicDirection: true),
                  ],
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            if (showArabic && showTranslation) const SizedBox(height: 10),
            if (showTranslation)
              Text.rich(
                TextSpan(
                  children: [
                    numberSpan(arabicDirection: false),
                    TextSpan(
                      text: translation ?? 'Meal yükleniyor…',
                      style: TextStyle(
                        fontSize: translationFontSize,
                        height: translationLineHeight,
                        color: scheme.onSurface.withValues(alpha: .94),
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
            if (bookmarked || hasNote) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bookmarked)
                    Icon(Icons.bookmark_rounded, size: 15, color: scheme.onSurfaceVariant),
                  if (bookmarked && hasNote) const SizedBox(width: 5),
                  if (hasNote)
                    Icon(Icons.comment_outlined, size: 15, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ],
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
    required this.onCompare,
  });

  final String reference;
  final int count;
  final VoidCallback onClose;
  final VoidCallback onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(26),
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Seçimi kapat',
                ),
                Expanded(
                  child: Text(
                    reference,
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
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
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
                  _SelectionAction(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Karşılaştır',
                    onTap: onCompare,
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
        scale: _pressed ? .94 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          constraints: const BoxConstraints(minWidth: 68),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 21),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionChoice extends StatelessWidget {
  const _VersionChoice({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  code,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
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

class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl({
    required this.title,
    required this.value,
    required this.preview,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String title;
  final int value;
  final String preview;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(preview, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onDecrease,
            icon: const Icon(Icons.text_decrease_rounded),
            tooltip: 'Küçült',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          IconButton.filledTonal(
            onPressed: onIncrease,
            icon: const Icon(Icons.text_increase_rounded),
            tooltip: 'Büyüt',
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

class _TranslationError extends StatelessWidget {
  const _TranslationError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Türkçe meal paketi açılamadı. Arapça metin kullanılabilir.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 44, color: scheme.primary),
            const SizedBox(height: 14),
            const Text(
              'Sure, ayet veya meal içinde ara',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Örnek: “Bakara”, “2:255” veya “sabır”. Arama cihazdaki offline meal üzerinde yapılır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.surah,
    required this.ayah,
    required this.title,
    required this.subtitle,
    this.isSurah = false,
  });

  final int surah;
  final int ayah;
  final String title;
  final String subtitle;
  final bool isSurah;
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final _SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(
          result.isSurah ? Icons.menu_book_rounded : Icons.format_quote_rounded,
          color: scheme.primary,
        ),
        title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: result.subtitle.isEmpty
            ? null
            : Text(
                result.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
