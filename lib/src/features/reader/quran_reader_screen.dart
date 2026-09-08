import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  int _anchorAyah = 1;
  bool _didRestorePosition = false;
  final Set<int> _selectedAyahs = <int>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_ContinuousVerseTextState> _textKey =
      GlobalKey<_ContinuousVerseTextState>();
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
    _scrollController.dispose();
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
    _didRestorePosition = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReaderRequest();
      _scheduleScrollToAyah(_anchorAyah);
    });
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
    });
    if (save) {
      AppSettingsScope.of(context).saveReadingPosition(
        surah: surah.number,
        ayah: safeAyah,
      );
    }
    HapticFeedback.selectionClick();
    _scheduleScrollToAyah(safeAyah);
  }

  void _openSurahAtStart(int surahNumber) {
    final surah = surahByNumber(surahNumber);
    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = 1;
      _selectedAyahs.clear();
    });
    AppSettingsScope.of(context).saveReadingPosition(surah: surah.number, ayah: 1);
    HapticFeedback.selectionClick();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _scheduleScrollToAyah(int ayah, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = _textKey.currentState;
      final globalY = state?.globalYForAyah(ayah);
      if (globalY != null && _scrollController.hasClients) {
        final desiredY = MediaQuery.paddingOf(context).top + 88;
        final delta = globalY - desiredY;
        final target = (_scrollController.offset + delta)
            .clamp(0.0, _scrollController.position.maxScrollExtent)
            .toDouble();
        _scrollController.animateTo(
          target,
          duration: attempt == 0
              ? const Duration(milliseconds: 280)
              : Duration.zero,
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (attempt < 5) {
        Future<void>.delayed(const Duration(milliseconds: 70), () {
          if (mounted) _scheduleScrollToAyah(ayah, attempt: attempt + 1);
        });
      }
    });
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

  String _activeVersionCode(AppSettings settings) =>
      settings.readerMode == ReaderDisplayMode.arabic
          ? 'AR'
          : translationCatalog.first.code;

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
            left: 10,
            right: 10,
            bottom: 76,
            child: IgnorePointer(
              ignoring: _selectedAyahs.isEmpty,
              child: AnimatedSlide(
                offset: _selectedAyahs.isEmpty
                    ? const Offset(0, 1.15)
                    : Offset.zero,
                duration: const Duration(milliseconds: 210),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _selectedAyahs.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 150),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _saveVisibleReadingPosition();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _surahHeader(surah, settings),
            if (translationError && settings.readerMode != ReaderDisplayMode.arabic)
              _TranslationError(onRetry: () => setState(() {})),
            _ContinuousVerseText(
              key: _textKey,
              surahNumber: _surahNumber,
              verseCount: surah.verseCount,
              translations: translations,
              mode: settings.readerMode,
              textSize: settings.readerTextSize,
              lineHeight: settings.readerMode == ReaderDisplayMode.arabic
                  ? settings.arabicLineHeight
                  : settings.translationLineHeight,
              selectedAyahs: _selectedAyahs,
              settings: settings,
              onAyahTap: _toggleAyahSelection,
              onNoteTap: _openNoteForAyah,
            ),
          ],
        ),
      ),
    );
  }

  void _saveVisibleReadingPosition() {
    if (!mounted) return;
    final targetY = MediaQuery.paddingOf(context).top + 100;
    final ayah = _textKey.currentState?.ayahClosestToGlobalY(targetY);
    if (ayah == null) return;
    AppSettingsScope.of(context).saveReadingPosition(
      surah: _surahNumber,
      ayah: ayah,
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
    final arabicMode = settings.readerMode == ReaderDisplayMode.arabic;
    final hasSeparateBasmala = surah.number != 1 && surah.number != 9;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            arabicMode ? surah.nameAr : surah.nameTr,
            textDirection: arabicMode ? TextDirection.rtl : TextDirection.ltr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontSize: 31,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.verseCount} ayet',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (arabicMode && hasSeparateBasmala) ...[
            const SizedBox(height: 24),
            Text(
              quran.basmala,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: settings.readerTextSize,
                height: settings.arabicLineHeight,
              ),
            ),
          ],
          const SizedBox(height: 12),
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
                subtitle: const Text('Ortak metin boyutu ve satır aralığı'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReadingAppearance();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Okuma metni'),
                subtitle: Text(
                  '${_activeVersionCode(AppSettingsScope.of(context))} · çevrimdışı',
                ),
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
        heightFactor: .58,
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
                  title: 'Metin boyutu',
                  value: settings.readerTextSize.round(),
                  preview: settings.readerMode == ReaderDisplayMode.arabic
                      ? 'بِسْمِ اللَّهِ'
                      : 'Kuran meali',
                  onDecrease: () {
                    settings.setReaderTextSize(settings.readerTextSize - 1.5);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                  onIncrease: () {
                    settings.setReaderTextSize(settings.readerTextSize + 1.5);
                    HapticFeedback.selectionClick();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Satır aralığı',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
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
                const SizedBox(height: 20),
                Text(
                  'Boyut ayarı seçili metinden bağımsızdır. RWD’den Arapçaya geçseniz de aynı okuma boyutu korunur.',
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
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final result = results[index];
                                  return _SearchResultTile(
                                    result: result,
                                    onTap: () =>
                                        Navigator.pop(sheetContext, result),
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

    final numeric =
        RegExp(r'^(\d{1,3})\s*[:/.\- ]\s*(\d{1,3})$').firstMatch(query);
    if (numeric != null) {
      final surahNumber = int.tryParse(numeric.group(1)!);
      final ayah = int.tryParse(numeric.group(2)!);
      if (surahNumber != null &&
          ayah != null &&
          surahNumber >= 1 &&
          surahNumber <= 114) {
        final surah = surahByNumber(surahNumber);
        if (ayah >= 1 && ayah <= surah.verseCount) {
          addResult(
            _SearchResult(
              surah: surahNumber,
              ayah: ayah,
              title: '${surah.nameTr} $surahNumber:$ayah',
              subtitle: translations['$surahNumber:$ayah'] ?? '',
            ),
          );
        }
      }
    }

    for (final surah in surahCatalog) {
      final normalizedName = _normalizeSearch(surah.nameTr);
      if (normalizedName.contains(query) ||
          _normalizeSearch(surah.nameAr).contains(query)) {
        addResult(
          _SearchResult(
            surah: surah.number,
            ayah: 1,
            title: '${surah.nameTr} · ${surah.verseCount} ayet',
            subtitle: surah.nameAr,
            isSurah: true,
          ),
        );
      }
      if (query.startsWith('$normalizedName ')) {
        final possibleAyah =
            int.tryParse(query.substring(normalizedName.length).trim());
        if (possibleAyah != null &&
            possibleAyah >= 1 &&
            possibleAyah <= surah.verseCount) {
          addResult(
            _SearchResult(
              surah: surah.number,
              ayah: possibleAyah,
              title: '${surah.nameTr} ${surah.number}:$possibleAyah',
              subtitle: translations['${surah.number}:$possibleAyah'] ?? '',
            ),
          );
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
        if (surahNumber == null ||
            ayah == null ||
            surahNumber < 1 ||
            surahNumber > 114) {
          continue;
        }
        final surah = surahByNumber(surahNumber);
        addResult(
          _SearchResult(
            surah: surahNumber,
            ayah: ayah,
            title: '${surah.nameTr} $surahNumber:$ayah',
            subtitle: entry.value,
          ),
        );
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
                          onTap: () =>
                              Navigator.pop(sheetContext, surah.number),
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
                'Okuyucuda aynı anda tek metin gösterilir.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _VersionChoice(
                code: candidate.code,
                title: 'Türkçe Tercüme',
                subtitle: '${candidate.publisher} · çevrimdışı',
                selected: settings.readerMode == ReaderDisplayMode.translation,
                onTap: () => Navigator.pop(
                  sheetContext,
                  ReaderDisplayMode.translation,
                ),
              ),
              const SizedBox(height: 8),
              _VersionChoice(
                code: 'AR',
                title: 'Arapça · Orijinal Kuran metni',
                subtitle: 'Tanzil.net · çevrimdışı',
                selected: settings.readerMode == ReaderDisplayMode.arabic,
                onTap: () => Navigator.pop(
                  sheetContext,
                  ReaderDisplayMode.arabic,
                ),
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
    final visibleAyah = settings.lastAyah;
    await settings.setReaderMode(picked);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    _scheduleScrollToAyah(visibleAyah);
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
      await settings.setHighlightForSelection(
        _surahNumber,
        selected,
        picked,
      );
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _clearSelection();
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
    _clearSelection();
  }

  Future<void> _copySelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    final translations = await _turkishTranslation;
    if (!mounted) return;

    final body = settings.readerMode == ReaderDisplayMode.arabic
        ? selected.map((ayah) => quran.getVerse(_surahNumber, ayah)).join(' ')
        : selected
            .map((ayah) => translations['$_surahNumber:$ayah'])
            .whereType<String>()
            .join(' ');
    final text =
        '$body\n\n${_selectionReference()} · ${_activeVersionCode(settings)}';

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seçili ayet kopyalandı')),
    );
    _clearSelection();
  }

  Future<void> _showCompareSheet() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final translations = await _turkishTranslation;
    if (!mounted) return;
    final settings = AppSettingsScope.of(context);
    final currentCode = _activeVersionCode(settings);
    final shownCodes = <String>[currentCode];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            String textFor(String code) {
              if (code == 'AR') {
                return selected
                    .map((ayah) => quran.getVerse(_surahNumber, ayah))
                    .join(' ');
              }
              return selected
                  .map((ayah) => translations['$_surahNumber:$ayah'])
                  .whereType<String>()
                  .join(' ');
            }

            String titleFor(String code) => code == 'AR'
                ? 'Arapça · Orijinal Kuran metni'
                : 'Türkçe Tercüme';

            Future<void> addVersion() async {
              final available = <_CompareVersion>[
                if (!shownCodes.contains(translationCatalog.first.code))
                  _CompareVersion(
                    code: translationCatalog.first.code,
                    title: 'Türkçe Tercüme',
                  ),
                if (!shownCodes.contains('AR'))
                  const _CompareVersion(
                    code: 'AR',
                    title: 'Arapça · Orijinal Kuran metni',
                  ),
              ];
              if (available.isEmpty) return;
              final picked = await showModalBottomSheet<_CompareVersion>(
                context: sheetContext,
                showDragHandle: true,
                builder: (pickerContext) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metin ekle',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final version in available)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 44,
                              child: Text(
                                version.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(version.title),
                            trailing: const Icon(Icons.add_rounded),
                            onTap: () =>
                                Navigator.pop(pickerContext, version),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              if (picked != null) {
                HapticFeedback.selectionClick();
                setSheetState(() => shownCodes.add(picked.code));
              }
            }

            Widget versionBlock(String code) {
              final arabic = code == 'AR';
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            titleFor(code),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      textFor(code),
                      textDirection:
                          arabic ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: settings.readerTextSize,
                        height: arabic
                            ? settings.arabicLineHeight
                            : settings.translationLineHeight,
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
                              'Metinleri Karşılaştır',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _selectionReference(),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                  child: ListView.separated(
                    itemCount: shownCodes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => versionBlock(shownCodes[index]),
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
                        onPressed: shownCodes.length >= 2 ? null : addVersion,
                        icon: const Icon(Icons.add_rounded, size: 30),
                        label: const Text('Metin Ekle'),
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

    if (mounted) _clearSelection();
  }

  Future<void> _openNoteForAyah(int ayah) async {
    final settings = AppSettingsScope.of(context);
    final key = settings.noteKeyForAyah(_surahNumber, ayah);
    if (key == null) return;
    final ayahs = settings.selectionAyahs(key, _surahNumber);
    if (ayahs == null || ayahs.isEmpty) return;
    setState(() {
      _selectedAyahs
        ..clear()
        ..addAll(ayahs);
    });
    HapticFeedback.selectionClick();
    await _editSelectionNote(sourceOverride: settings.noteSourceForKey(key));
  }

  Future<void> _editSelectionNote({String? sourceOverride}) async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;
    final translations = await _turkishTranslation;
    if (!mounted) return;

    final sourceCode = sourceOverride ?? _activeVersionCode(settings);
    final arabicSource = sourceCode == 'AR';
    final selectedText = arabicSource
        ? selected.map((ayah) => quran.getVerse(_surahNumber, ayah)).join(' ')
        : selected
            .map((ayah) => translations['$_surahNumber:$ayah'])
            .whereType<String>()
            .join(' ');

    final controller = TextEditingController(
      text: settings.noteForSelection(_surahNumber, selected) ?? '',
    );

    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: .92,
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
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: 'Notunuzu yazın',
                    filled: true,
                    fillColor: scheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_selectionReference()} · $sourceCode',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                        selectedText,
                        textDirection: arabicSource
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        textAlign:
                            arabicSource ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize:
                              math.min(settings.readerTextSize, 27.0).toDouble(),
                          height: arabicSource
                              ? settings.arabicLineHeight
                              : settings.translationLineHeight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
      await settings.setNoteForSelection(
        _surahNumber,
        selected,
        value,
        sourceCode: sourceCode,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _clearSelection();
    }
  }
}

class _ContinuousVerseText extends StatefulWidget {
  const _ContinuousVerseText({
    required this.surahNumber,
    required this.verseCount,
    required this.translations,
    required this.mode,
    required this.textSize,
    required this.lineHeight,
    required this.selectedAyahs,
    required this.settings,
    required this.onAyahTap,
    required this.onNoteTap,
    super.key,
  });

  final int surahNumber;
  final int verseCount;
  final Map<String, String> translations;
  final ReaderDisplayMode mode;
  final double textSize;
  final double lineHeight;
  final Set<int> selectedAyahs;
  final AppSettings settings;
  final ValueChanged<int> onAyahTap;
  final ValueChanged<int> onNoteTap;

  @override
  State<_ContinuousVerseText> createState() => _ContinuousVerseTextState();
}

class _ContinuousVerseTextState extends State<_ContinuousVerseText> {
  final GlobalKey _richTextKey = GlobalKey();
  final Map<int, TapGestureRecognizer> _recognizers =
      <int, TapGestureRecognizer>{};
  final Map<int, int> _textOffsets = <int, int>{};

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant _ContinuousVerseText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecognizers();
  }

  void _syncRecognizers() {
    final needed = <int>{
      for (var ayah = 1; ayah <= widget.verseCount; ayah++) ayah,
    };
    for (final ayah in _recognizers.keys.toList()) {
      if (!needed.contains(ayah)) {
        _recognizers.remove(ayah)?.dispose();
      }
    }
    for (final ayah in needed) {
      final recognizer = _recognizers.putIfAbsent(
        ayah,
        () => TapGestureRecognizer(),
      );
      recognizer.onTap = () => widget.onAyahTap(ayah);
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  RenderParagraph? get _paragraph {
    final renderObject = _richTextKey.currentContext?.findRenderObject();
    return renderObject is RenderParagraph ? renderObject : null;
  }

  double? globalYForAyah(int ayah) {
    final paragraph = _paragraph;
    final offset = _textOffsets[ayah];
    if (paragraph == null || offset == null || !paragraph.attached) return null;
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: offset),
      Rect.zero,
    );
    return paragraph.localToGlobal(caret).dy;
  }

  int? ayahClosestToGlobalY(double targetY) {
    if (_textOffsets.isEmpty) return null;
    int? bestAyah;
    var bestDistance = double.infinity;
    for (final ayah in _textOffsets.keys) {
      final y = globalYForAyah(ayah);
      if (y == null) continue;
      final distance = (y - targetY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestAyah = ayah;
      }
    }
    return bestAyah;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabicMode = widget.mode == ReaderDisplayMode.arabic;
    final spans = <InlineSpan>[];
    var plainOffset = 0;
    _textOffsets.clear();

    for (var ayah = 1; ayah <= widget.verseCount; ayah++) {
      _textOffsets[ayah] = plainOffset;
      final selected = widget.selectedAyahs.contains(ayah);
      final highlight = widget.settings.highlightFor(widget.surahNumber, ayah);
      final highlightedColor = highlight == null
          ? null
          : _highlightMaterialColor(highlight).withValues(alpha: .92);
      final foreground = highlightedColor == null
          ? scheme.onSurface
          : ThemeData.estimateBrightnessForColor(highlightedColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black;
      final noteKey = widget.settings.noteKeyForAyah(widget.surahNumber, ayah);
      final bookmarked = widget.settings.isBookmarked(widget.surahNumber, ayah);
      final text = arabicMode
          ? quran.getVerse(widget.surahNumber, ayah)
          : widget.translations['${widget.surahNumber}:$ayah'] ??
              'Meal yükleniyor…';

      final numberStyle = TextStyle(
        color: highlightedColor == null
            ? scheme.onSurfaceVariant
            : foreground.withValues(alpha: .78),
        fontSize: math.max(11.0, widget.textSize * .52).toDouble(),
        fontWeight: FontWeight.w700,
        backgroundColor: highlightedColor,
      );
      final verseStyle = TextStyle(
        color: foreground,
        fontFamily: 'serif',
        fontSize: widget.textSize,
        height: widget.lineHeight,
        backgroundColor: highlightedColor,
        decoration: selected ? TextDecoration.underline : TextDecoration.none,
        decorationColor: scheme.onSurface.withValues(alpha: .88),
        decorationStyle: TextDecorationStyle.dotted,
        decorationThickness: 1.6,
      );

      if (arabicMode) {
        spans.add(
          TextSpan(
            text: text,
            style: verseStyle,
            recognizer: _recognizers[ayah],
          ),
        );
        plainOffset += text.length;
        final number = '  $ayah';
        spans.add(TextSpan(text: number, style: numberStyle));
        plainOffset += number.length;
      } else {
        final number = '$ayah  ';
        spans.add(TextSpan(text: number, style: numberStyle));
        plainOffset += number.length;
        spans.add(
          TextSpan(
            text: text,
            style: verseStyle,
            recognizer: _recognizers[ayah],
          ),
        );
        plainOffset += text.length;
      }

      if (noteKey != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onNoteTap(ayah),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
        plainOffset += 1;
      }
      if (bookmarked) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.bookmark_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
        plainOffset += 1;
      }
      spans.add(const TextSpan(text: '  '));
      plainOffset += 2;
    }

    return Text.rich(
      TextSpan(children: spans),
      key: _richTextKey,
      textDirection: arabicMode ? TextDirection.rtl : TextDirection.ltr,
      textAlign: arabicMode ? TextAlign.right : TextAlign.left,
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
      elevation: 14,
      borderRadius: BorderRadius.circular(24),
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 22),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
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
            ),
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
          constraints: const BoxConstraints(minWidth: 64),
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11,
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

class _CompareVersion {
  const _CompareVersion({required this.code, required this.title});

  final String code;
  final String title;
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _highlightMaterialColor(color),
            ),
          ),
        ),
      );
}

Color _highlightMaterialColor(VerseHighlightColor color) => switch (color) {
      VerseHighlightColor.yellow => const Color(0xFFFFEB00),
      VerseHighlightColor.green => const Color(0xFF45E879),
      VerseHighlightColor.blue => const Color(0xFF18C4E8),
      VerseHighlightColor.orange => const Color(0xFFFFB45E),
      VerseHighlightColor.pink => const Color(0xFFE88AC6),
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
                Text(
                  preview,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
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
            child: Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
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
          IconButton(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, color: scheme.onErrorContainer),
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
              'Örnek: “Bakara”, “2:255” veya “sabır”. Arama cihazdaki çevrimdışı meal üzerinde yapılır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
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
          result.isSurah
              ? Icons.menu_book_rounded
              : Icons.format_quote_rounded,
          color: scheme.primary,
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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
