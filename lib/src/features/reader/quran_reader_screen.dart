import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/quran_verse_metadata.dart';
import '../../data/surah_catalog.dart';
import '../../data/surah_localization.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import '../settings/quran_translation_catalog_screen.dart';
import 'reader_audio_sheet.dart';
import 'reader_note_sheet.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  int _surahNumber = 1;
  int _anchorAyah = 1;
  bool _didRestorePosition = false;
  bool _readerChromeVisible = true;
  bool _audioQuickControlsVisible = true;
  double _horizontalDragDistance = 0;
  double _verticalPointerDistance = 0;
  int _visibleAyah = 1;
  int? _lastAudioAyah;
  bool _audioFollowEnabled = true;
  bool _manualReaderScroll = false;
  late final ReaderAudioController _audioController;
  final Set<int> _selectedAyahs = <int>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_ContinuousVerseTextState> _textKey =
      GlobalKey<_ContinuousVerseTextState>();
  String? _cachedSourceId;
  Future<Map<String, String>>? _cachedTranslationFuture;

  @override
  void initState() {
    super.initState();
    _audioController = ReaderAudioController();
    _audioController.addListener(_handleAudioChanged);
    AppNavigation.instance.readerRequest.addListener(_handleReaderRequest);
  }

  void _handleAudioChanged() {
    if (!mounted) return;
    if (_audioController.isConfigured &&
        _audioController.surahNumber == _surahNumber &&
        _lastAudioAyah != _audioController.currentAyah) {
      _lastAudioAyah = _audioController.currentAyah;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_audioFollowEnabled && !_manualReaderScroll) {
          _scheduleScrollToAyah(
            _audioController.currentAyah,
            audioFollow: true,
          );
        }
        AppSettingsScope.of(context).saveReadingPosition(
          surah: _surahNumber,
          ayah: _audioController.currentAyah,
        );
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    AppNavigation.instance.setReaderSelectionActive(false);
    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);
    _audioController.removeListener(_handleAudioChanged);
    _audioController.dispose();
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
    _visibleAyah = _anchorAyah;
    _didRestorePosition = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReaderRequest();
      _scheduleScrollToAyah(_anchorAyah);
      final config = _audioConfig(settings);
      if (config != null) {
        _primeAudio(config, 1);
      }
    });
  }

  Future<Map<String, String>> _translationFuture(AppSettings settings) {
    if (settings.readerUsesArabic) {
      return Future<Map<String, String>>.value(const <String, String>{});
    }
    if (_cachedSourceId != settings.selectedQuranSourceId ||
        _cachedTranslationFuture == null) {
      _cachedSourceId = settings.selectedQuranSourceId;
      _cachedTranslationFuture = TranslationRepository.instance
          .loadSourceVerses(settings.selectedQuranSourceId);
    }
    return _cachedTranslationFuture!;
  }

  void _invalidateTranslationFuture() {
    _cachedSourceId = null;
    _cachedTranslationFuture = null;
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
      _visibleAyah = safeAyah;
      _selectedAyahs.clear();
    });
    AppNavigation.instance.setReaderSelectionActive(false);
    if (save) {
      AppSettingsScope.of(context)
          .saveReadingPosition(surah: surah.number, ayah: safeAyah);
    }
    HapticFeedback.selectionClick();
    _scheduleScrollToAyah(safeAyah);
  }

  void _openSurahAtStart(int surahNumber) {
    _audioController.stop();
    _lastAudioAyah = null;
    final surah = surahByNumber(surahNumber);
    setState(() {
      _surahNumber = surah.number;
      _anchorAyah = 1;
      _visibleAyah = 1;
      _selectedAyahs.clear();
    });
    AppNavigation.instance.setReaderSelectionActive(false);
    AppSettingsScope.of(context)
        .saveReadingPosition(surah: surah.number, ayah: 1);
    HapticFeedback.selectionClick();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _scheduleScrollToAyah(
    int ayah, {
    int attempt = 0,
    bool audioFollow = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = _textKey.currentState;
      final globalY = state?.globalYForAyah(ayah);
      if (globalY != null && _scrollController.hasClients) {
        final desiredY = audioFollow
            ? MediaQuery.sizeOf(context).height * .28
            : MediaQuery.paddingOf(context).top + 88;
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
          if (mounted) {
            _scheduleScrollToAyah(
              ayah,
              attempt: attempt + 1,
              audioFollow: audioFollow,
            );
          }
        });
      }
    });
  }

  List<int> get _selection {
    final values = _selectedAyahs.toList()..sort();
    return values;
  }

  String _readerLanguageCode() {
    final settings = AppSettingsScope.of(context);
    if (settings.readerUsesArabic) return 'ar';
    return translationById(settings.selectedQuranSourceId)?.languageCode ??
        Localizations.localeOf(context).languageCode;
  }

  String _surahName(SurahInfo surah) =>
      localizedSurahName(surah.number, _readerLanguageCode());

  String _selectionReference() {
    final surah = surahByNumber(_surahNumber);
    final values = _selection;
    if (values.isEmpty) return '${_surahName(surah)} $_surahNumber';
    if (values.length == 1) {
      return '${_surahName(surah)} $_surahNumber:${values.single}';
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
    return '${_surahName(surah)} $_surahNumber:$ayahPart';
  }

  void _toggleAyahSelection(int ayahNumber) {
    setState(() {
      if (!_selectedAyahs.add(ayahNumber)) {
        _selectedAyahs.remove(ayahNumber);
      }
    });
    AppNavigation.instance.setReaderSelectionActive(_selectedAyahs.isNotEmpty);
    HapticFeedback.selectionClick();
    AppSettingsScope.of(context)
        .saveReadingPosition(surah: _surahNumber, ayah: ayahNumber);
  }

  void _clearSelection() {
    if (_selectedAyahs.isEmpty) {
      AppNavigation.instance.setReaderSelectionActive(false);
      return;
    }
    setState(_selectedAyahs.clear);
    AppNavigation.instance.setReaderSelectionActive(false);
  }

  String _activeVersionCode(AppSettings settings) {
    if (settings.readerUsesArabic) return 'AR';
    return translationById(settings.selectedQuranSourceId)?.code ?? 'RWD';
  }

  String _sourceIdForCode(String code) {
    if (code == 'AR') return arabicOriginalSourceId;
    for (final info in translationCatalog) {
      if (info.code == code) return info.id;
    }
    return bundledTurkishTranslationId;
  }

  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) =>
      readerAudioConfigFor(settings.selectedQuranSourceId);

  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {
    final surah = surahByNumber(_surahNumber);
    final sameSession =
        _audioController.isConfigured &&
        _audioController.config?.id == config.id &&
        _audioController.surahNumber == _surahNumber;
    final targetAyah = sameSession ? _audioController.currentAyah : 1;
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: targetAyah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
  }

  Future<void> _primeAudio(ReaderAudioSourceConfig config, int ayah) async {
    final surah = surahByNumber(_surahNumber);
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: ayah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
  }

  Future<void> _toggleAudio(ReaderAudioSourceConfig config) async {
    await _prepareAudio(config);
    final wasPlaying = _audioController.isPlaying;
    await _audioController.toggle();
    if (!wasPlaying && _audioController.isPlaying && mounted) {
      setState(() {
        _audioFollowEnabled = true;
        _manualReaderScroll = false;
      });
      _scheduleScrollToAyah(_audioController.currentAyah, audioFollow: true);
    }
  }

  Future<void> _skipAudio(ReaderAudioSourceConfig config, int delta) async {
    await _prepareAudio(config);
    if (delta < 0) {
      await _audioController.previous();
    } else {
      await _audioController.next();
    }
  }

  Future<void> _listenSelection(ReaderAudioSourceConfig config) async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final targetAyah = selected.first;
    await _prepareAudio(config);
    await _audioController.playAyah(targetAyah);
    if (!mounted) return;
    setState(() {
      _audioFollowEnabled = true;
      _manualReaderScroll = false;
    });
    _clearSelection();
    _scheduleScrollToAyah(targetAyah, audioFollow: true);
  }

  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {
    await _prepareAudio(config);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ReaderAudioSheet(
        controller: _audioController,
        surahLabel: _surahName(surahByNumber(_surahNumber)),
        quickControlsVisible: _audioQuickControlsVisible,
        onQuickControlsVisibilityChanged: (visible) {
          if (mounted) setState(() => _audioQuickControlsVisible = visible);
        },
      ),
    );
  }

  void _setReaderChromeVisible(bool visible) {
    if (!mounted || _readerChromeVisible == visible) return;
    setState(() => _readerChromeVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final surah = surahByNumber(_surahNumber);
    final settings = AppSettingsScope.of(context);
    final audioConfig = _audioConfig(settings);
    final showTopChrome = _readerChromeVisible || _selectedAyahs.isNotEmpty;
    final showQuickAudio =
        _selectedAyahs.isEmpty &&
        _readerChromeVisible &&
        audioConfig != null &&
        _audioQuickControlsVisible;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<Map<String, String>>(
              future: _translationFuture(settings),
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
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              ignoring: !showTopChrome,
              child: AnimatedSlide(
                offset: showTopChrome ? Offset.zero : const Offset(0, -1.05),
                duration: const Duration(milliseconds: 210),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: showTopChrome ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: Material(
                    color: scheme.surface,
                    child: _readerTopChrome(
                      scheme: scheme,
                      l10n: l10n,
                      surah: surah,
                      settings: settings,
                      audioConfig: audioConfig,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (audioConfig != null && _audioQuickControlsVisible)
            Positioned(
              left: 74,
              right: 74,
              bottom: 82,
              child: IgnorePointer(
                ignoring: !showQuickAudio,
                child: AnimatedSlide(
                  offset: showQuickAudio ? Offset.zero : const Offset(0, .85),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: showQuickAudio ? 1 : 0,
                    duration: const Duration(milliseconds: 165),
                    curve: Curves.easeOut,
                    child: Material(
                      elevation: showQuickAudio ? 8 : 0,
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () => _skipAudio(audioConfig, -1),
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            IconButton.filled(
                              onPressed: () => _toggleAudio(audioConfig),
                              icon: Icon(
                                _audioController.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _skipAudio(audioConfig, 1),
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_audioController.isPlaying && !_audioFollowEnabled)
            Positioned(
              right: 16,
              bottom: 150,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _audioFollowEnabled = true;
                    _manualReaderScroll = false;
                  });
                  _scheduleScrollToAyah(
                    _audioController.currentAyah,
                    audioFollow: true,
                  );
                },
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Okunan ayete dön'
                      : 'Return to current verse',
                ),
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
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
                    onHighlight: _applyHighlight,
                    onBookmark: _bookmarkSelection,
                    onNote: _editSelectionNote,
                    onListen: audioConfig == null
                        ? null
                        : () => _listenSelection(audioConfig),
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

  Widget _readerTopChrome({
    required ColorScheme scheme,
    required AppLocalizations l10n,
    required SurahInfo surah,
    required AppSettings settings,
    required ReaderAudioSourceConfig? audioConfig,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
                        tooltip: l10n.text('closeSelection'),
                      ),
                      Expanded(
                        child: Text(
                          '${l10n.text('selectedPrefix')}: ${_selectionReference()}',
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
                                '${_surahName(surah)} ${surah.number}',
                                _showSurahs,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: scheme.outline.withValues(alpha: .28),
                            ),
                            SizedBox(
                              width: 82,
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
                    if (audioConfig != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showAudioPlayer(audioConfig),
                        icon: const Icon(Icons.volume_up_outlined, size: 27),
                        tooltip: l10n.text('listen'),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _showSearch,
                      icon: const Icon(Icons.search_rounded, size: 28),
                      tooltip: l10n.text('readerSearchTooltip'),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _showReaderMenu,
                      icon: const Icon(Icons.more_horiz_rounded, size: 29),
                      tooltip: l10n.text('readerSettingsTooltip'),
                    ),
                  ],
                ),
        ),
        const Divider(height: 1),
      ],
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
        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
          if (notification.direction != ScrollDirection.idle &&
              _audioController.isPlaying) {
            _manualReaderScroll = true;
            if (_audioFollowEnabled) {
              setState(() => _audioFollowEnabled = false);
            }
          }
          if (_scrollController.hasClients && _scrollController.offset < 18) {
            _setReaderChromeVisible(true);
          } else if (notification.direction == ScrollDirection.reverse) {
            _setReaderChromeVisible(false);
          } else if (notification.direction == ScrollDirection.forward) {
            _setReaderChromeVisible(true);
          }
        }
        if (notification is ScrollEndNotification) {
          _saveVisibleReadingPosition();
        }
        return false;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _horizontalDragDistance = 0;
          _verticalPointerDistance = 0;
        },
        onPointerMove: (event) {
          _horizontalDragDistance += event.delta.dx;
          _verticalPointerDistance += event.delta.dy.abs();
        },
        onPointerUp: (_) => _handleHorizontalReaderSwipe(),
        onPointerCancel: (_) {
          _horizontalDragDistance = 0;
          _verticalPointerDistance = 0;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            22,
            96,
            22,
            _selectedAyahs.isEmpty ? 118 : 78,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _surahHeader(surah, settings),
              _verseMetadataStrip(),
              if (translationError && !settings.readerUsesArabic)
                _TranslationError(
                  onRetry: () {
                    _invalidateTranslationFuture();
                    setState(() {});
                  },
                ),
              _ContinuousVerseText(
                key: _textKey,
                surahNumber: _surahNumber,
                verseCount: surah.verseCount,
                translations: translations,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verseMetadataStrip() {
    final metadata = quranVerseMetadata(_surahNumber, _visibleAyah);
    final scheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    String label(String tr, String en, String ar, String az, String ru) =>
        switch (language) {
          'tr' => tr,
          'ar' => ar,
          'az' => az,
          'ru' => ru,
          _ => en,
        };

    final values = <String>[
      '${label('Cüz', 'Juz', 'الجزء', 'Cüz', 'Джуз')} ${metadata.juz}',
      '${label('Sayfa', 'Page', 'الصفحة', 'Səhifə', 'Страница')} ${metadata.page}',
      if (metadata.isSajdah)
        label(
          'Secde ayeti',
          'Sajdah verse',
          'آية سجدة',
          'Səcdə ayəsi',
          'Аят саджда',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: values
            .map(
              (value) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  void _handleHorizontalReaderSwipe() {
    if (_selectedAyahs.isNotEmpty) return;
    final horizontal = _horizontalDragDistance;
    final vertical = _verticalPointerDistance;
    _horizontalDragDistance = 0;
    _verticalPointerDistance = 0;
    if (horizontal.abs() < 92) return;
    if (vertical > horizontal.abs() * .55) return;
    if (horizontal < 0 && _surahNumber < 114) {
      _openSurahAtStart(_surahNumber + 1);
    } else if (horizontal > 0 && _surahNumber > 1) {
      _openSurahAtStart(_surahNumber - 1);
    }
  }

  void _saveVisibleReadingPosition() {
    if (!mounted) return;
    final targetY = MediaQuery.paddingOf(context).top + 100;
    final ayah = _textKey.currentState?.ayahClosestToGlobalY(targetY);
    if (ayah == null) return;
    if (_visibleAyah != ayah) {
      setState(() => _visibleAyah = ayah);
    }
    final settings = AppSettingsScope.of(context);
    settings.saveReadingPosition(surah: _surahNumber, ayah: ayah);
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
    final l10n = context.l10n;
    final arabicMode = settings.readerUsesArabic;
    final hasSeparateBasmala = surah.number != 1 && surah.number != 9;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            arabicMode ? surah.nameAr : _surahName(surah),
            textDirection: arabicMode ? TextDirection.rtl : null,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontFamily: 'serif', fontSize: 31),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.verseCount} ${l10n.text('verseUnit')}',
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
    final l10n = context.l10n;
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
                title: Text(l10n.text('readerAppearanceMenu')),
                subtitle: Text(l10n.text('readerAppearanceMenuSubtitle')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReadingAppearance();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l10n.text('readingText')),
                subtitle: Text(
                  '${_activeVersionCode(AppSettingsScope.of(context))} · ${l10n.text('offline')}',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showTranslations();
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.text('arabicTextSource')),
                subtitle: Text(l10n.text('arabicTextSourceSubtitle')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReadingAppearance() async {
    final settings = AppSettingsScope.of(context);
    final l10n = context.l10n;
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
                Text(
                  l10n.text('readerAppearance'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _FontSizeControl(
                  title: l10n.text('textSize'),
                  value: settings.readerTextSize.round(),
                  preview: settings.readerUsesArabic
                      ? 'بِسْمِ اللَّهِ'
                      : l10n.text('quranTranslationPreview'),
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
                Text(
                  l10n.text('lineSpacing'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in ReaderLineSpacing.values)
                      ChoiceChip(
                        label: Text(switch (option) {
                          ReaderLineSpacing.compact => l10n.text('compact'),
                          ReaderLineSpacing.normal => l10n.text('normal'),
                          ReaderLineSpacing.relaxed => l10n.text('relaxed'),
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
                  l10n.text('readerSizeHint'),
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
    final settings = AppSettingsScope.of(context);
    Map<String, String> translations = const <String, String>{};
    if (!settings.readerUsesArabic) {
      try {
        translations = await TranslationRepository.instance.loadSourceVerses(
          settings.selectedQuranSourceId,
        );
      } catch (_) {
        if (!mounted) return;
      }
    }
    if (!mounted) return;
    final l10n = context.l10n;
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
              final results = _searchResults(
                query,
                translations,
                searchArabic: settings.readerUsesArabic,
              );
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
                        Expanded(
                          child: Text(
                            l10n.text('quranSearchTitle'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: InputDecoration(
                        hintText: l10n.text('quranSearchHint'),
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
                        ? Center(child: Text(l10n.text('noResults')))
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
    Map<String, String> translations, {
    required bool searchArabic,
  }) {
    final query = _normalizeSearch(rawQuery);
    if (query.isEmpty) return const <_SearchResult>[];
    final results = <_SearchResult>[];
    final seen = <String>{};

    void addResult(_SearchResult result) {
      final key = '${result.surah}:${result.ayah}';
      if (seen.add(key)) results.add(result);
    }

    final numeric = RegExp(r'^(\d{1,3})\s*[:/.\- ]\s*(\d{1,3})$')
        .firstMatch(query);
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
              title: '${_surahName(surah)} $surahNumber:$ayah',
              subtitle: searchArabic
                  ? quran.getVerse(surahNumber, ayah)
                  : translations['$surahNumber:$ayah'] ?? '',
            ),
          );
        }
      }
    }

    for (final surah in surahCatalog) {
      final normalizedAliases = surahSearchAliases(
        surah.number,
        _readerLanguageCode(),
      ).map(_normalizeSearch).toList(growable: false);
      if (normalizedAliases.any((name) => name.contains(query))) {
        addResult(
          _SearchResult(
            surah: surah.number,
            ayah: 1,
            title:
                '${_surahName(surah)} · ${surah.verseCount} ${context.l10n.text('verseUnit')}',
            subtitle: surah.nameAr,
            isSurah: true,
          ),
        );
      }
      for (final alias in normalizedAliases) {
        if (!query.startsWith('$alias ')) continue;
        final possibleAyah = int.tryParse(query.substring(alias.length).trim());
        if (possibleAyah != null &&
            possibleAyah >= 1 &&
            possibleAyah <= surah.verseCount) {
          addResult(
            _SearchResult(
              surah: surah.number,
              ayah: possibleAyah,
              title: '${_surahName(surah)} ${surah.number}:$possibleAyah',
              subtitle: searchArabic
                  ? quran.getVerse(surah.number, possibleAyah)
                  : translations['${surah.number}:$possibleAyah'] ?? '',
            ),
          );
        }
        break;
      }
    }

    if (query.length >= 2) {
      if (searchArabic) {
        for (final surah in surahCatalog) {
          for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
            if (results.length >= 60) break;
            final text = quran.getVerse(surah.number, ayah);
            if (!_normalizeSearch(text).contains(query)) continue;
            addResult(
              _SearchResult(
                surah: surah.number,
                ayah: ayah,
                title: '${_surahName(surah)} ${surah.number}:$ayah',
                subtitle: text,
              ),
            );
          }
          if (results.length >= 60) break;
        }
      } else {
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
              title: '${_surahName(surah)} $surahNumber:$ayah',
              subtitle: entry.value,
            ),
          );
        }
      }
    }

    return results.take(60).toList(growable: false);
  }

  String _normalizeSearch(String value) =>
      value.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  Future<void> _showSurahs() async {
    final l10n = context.l10n;
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
              final normalized = _normalizeSearch(query);
              final filtered = normalized.isEmpty
                  ? surahCatalog
                  : surahCatalog
                        .where((surah) {
                          final aliases = surahSearchAliases(
                            surah.number,
                            _readerLanguageCode(),
                          );
                          return aliases.any(
                                (name) =>
                                    _normalizeSearch(name).contains(normalized),
                              ) ||
                              surah.number.toString() == normalized;
                        })
                        .toList(growable: false);

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
                        Expanded(
                          child: Text(
                            l10n.text('surahs'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                        hintText: l10n.text('surahSearchHint'),
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
    final before = settings.selectedQuranSourceId;
    final visibleAyah = settings.lastAyah;

    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => const FractionallySizedBox(
        heightFactor: .93,
        child: QuranTranslationCatalogScreen(),
      ),
    );

    if (!mounted || settings.selectedQuranSourceId == before) return;
    await _audioController.stop();
    _lastAudioAyah = null;
    _invalidateTranslationFuture();
    HapticFeedback.selectionClick();
    setState(() {});
    _scheduleScrollToAyah(visibleAyah);
  }

  Future<void> _applyHighlight(VerseHighlightColor? color) async {
    final selected = _selection;
    if (selected.isEmpty) return;
    await AppSettingsScope.of(context)
        .setHighlightForSelection(_surahNumber, selected, color);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _clearSelection();
  }

  Future<void> _bookmarkSelection() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    await AppSettingsScope.of(context)
        .bookmarkSelection(_surahNumber, selected);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? context.l10n.text('verseSaved')
              : context.l10n.text('selectionSaved'),
        ),
      ),
    );
    _clearSelection();
  }

  Future<void> _copySelection() async {
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
    final text =
        '$body\n\n${_selectionReference()} · ${_activeVersionCode(settings)}';

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('selectionCopied'))),
    );
    _clearSelection();
  }

  Future<void> _showCompareSheet() async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    final l10n = context.l10n;
    final repo = TranslationRepository.instance;
    final installed = <TranslationInfo>[];
    final textMaps = <String, Map<String, String>>{};
    for (final info in translationCatalog) {
      if (await repo.isInstalled(info.id)) {
        installed.add(info);
        textMaps[info.id] = await repo.loadSourceVerses(info.id);
      }
    }
    if (!mounted) return;

    final shownSources = <String>[settings.selectedQuranSourceId];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            String textFor(String sourceId) {
              if (sourceId == arabicOriginalSourceId) {
                return selected
                    .map((ayah) => quran.getVerse(_surahNumber, ayah))
                    .join(' ');
              }
              final map = textMaps[sourceId] ?? const <String, String>{};
              return selected
                  .map((ayah) => map['$_surahNumber:$ayah'])
                  .whereType<String>()
                  .join(' ');
            }

            String titleFor(String sourceId) =>
                sourceId == arabicOriginalSourceId
                ? l10n.arabicOriginal
                : translationById(sourceId)?.name ?? sourceId;

            String codeFor(String sourceId) =>
                sourceId == arabicOriginalSourceId
                ? 'AR'
                : translationById(sourceId)?.code ?? sourceId;

            Future<void> addVersion() async {
              final available = <_CompareVersion>[
                for (final info in installed)
                  if (!shownSources.contains(info.id))
                    _CompareVersion(
                      sourceId: info.id,
                      code: info.code,
                      title: info.name,
                    ),
                if (!shownSources.contains(arabicOriginalSourceId))
                  _CompareVersion(
                    sourceId: arabicOriginalSourceId,
                    code: 'AR',
                    title: l10n.arabicOriginal,
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
                        Text(
                          l10n.text('addText'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final version in available)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 55,
                              child: Text(
                                version.code,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(version.title),
                            trailing: const Icon(Icons.add_rounded),
                            onTap: () => Navigator.pop(pickerContext, version),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              if (picked != null) {
                HapticFeedback.selectionClick();
                setSheetState(() => shownSources.add(picked.sourceId));
              }
            }

            Widget versionBlock(String sourceId) {
              final arabic = sourceId == arabicOriginalSourceId;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          codeFor(sourceId),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            titleFor(sourceId),
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
                      textFor(sourceId),
                      textDirection: arabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
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
                            Text(
                              l10n.text('compareTexts'),
                              style: const TextStyle(
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
                    itemCount: shownSources.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) =>
                        versionBlock(shownSources[index]),
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
                        onPressed: shownSources.length >= installed.length + 1
                            ? null
                            : addVersion,
                        icon: const Icon(Icons.add_rounded, size: 30),
                        label: Text(l10n.text('addText')),
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
    final sourceCode = settings.noteSourceForKey(key);
    final note = settings.noteEntries[key] ?? '';
    final ayahPart = ayahs.length == 1 ? '${ayahs.single}' : ayahs.join(',');
    final reference =
        '${_surahName(surahByNumber(_surahNumber))} $_surahNumber:$ayahPart';
    HapticFeedback.selectionClick();
    await showReaderPersonalNotePreview(
      context: context,
      reference: reference,
      note: note,
      sourceCode: sourceCode,
      onOpenArchive: () {
        AppNavigation.instance.tabRequest.value = 4;
      },
      onEdit: () async {
        if (!mounted) return;
        setState(() {
          _selectedAyahs
            ..clear()
            ..addAll(ayahs);
        });
        AppNavigation.instance.setReaderSelectionActive(true);
        await _editSelectionNote(sourceOverride: sourceCode);
      },
    );
  }

  Future<void> _editSelectionNote({String? sourceOverride}) async {
    final settings = AppSettingsScope.of(context);
    final selected = _selection;
    if (selected.isEmpty) return;

    final sourceCode = sourceOverride ?? _activeVersionCode(settings);
    final sourceId = _sourceIdForCode(sourceCode);
    final arabicSource = sourceId == arabicOriginalSourceId;
    Map<String, String> translations = const <String, String>{};
    if (!arabicSource) {
      try {
        translations = await TranslationRepository.instance.loadSourceVerses(
          sourceId,
        );
      } catch (_) {
        translations = await TranslationRepository.instance
            .loadBundledTurkish();
      }
    }
    if (!mounted) return;

    final selectedText = arabicSource
        ? selected.map((ayah) => quran.getVerse(_surahNumber, ayah)).join(' ')
        : selected
              .map((ayah) => translations['$_surahNumber:$ayah'])
              .whereType<String>()
              .join(' ');

    final controller = TextEditingController(
      text: settings.noteForSelection(_surahNumber, selected) ?? '',
    );
    final l10n = context.l10n;

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
                    Expanded(
                      child: Text(
                        l10n.text('note'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, controller.text),
                      child: Text(l10n.save),
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
                    hintText: l10n.text('noteHint'),
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
                  alignment: AlignmentDirectional.centerStart,
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
                        textAlign: arabicSource
                            ? TextAlign.right
                            : TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: math
                              .min(settings.readerTextSize, 27.0)
                              .toDouble(),
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
                        l10n.text('noteLocalOnly'),
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
    required this.activeAudioAyah,
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
  final int? activeAudioAyah;
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
      if (!needed.contains(ayah)) _recognizers.remove(ayah)?.dispose();
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
      final activeAudio = widget.activeAudioAyah == ayah;
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
                context.l10n.translationLoading;

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
        decoration: activeAudio || selected
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: activeAudio
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: .88),
        decorationStyle: activeAudio
            ? TextDecorationStyle.solid
            : TextDecorationStyle.dotted,
        decorationThickness: activeAudio ? 2.5 : 1.6,
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.note_alt_outlined,
                  size: 17,
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
    required this.onHighlight,
    required this.onBookmark,
    required this.onNote,
    required this.onListen,
    required this.onCopy,
    required this.onCompare,
  });

  final ValueChanged<VerseHighlightColor?> onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback? onListen;
  final VoidCallback onCopy;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
                _HighlightDot(color: color, onTap: () => onHighlight(color)),
              IconButton(
                onPressed: () => onHighlight(null),
                icon: const Icon(Icons.format_color_reset_rounded, size: 20),
                tooltip: l10n.text('removeHighlight'),
              ),
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color: scheme.outlineVariant,
              ),
              _SelectionAction(
                icon: Icons.bookmark_border_rounded,
                label: l10n.save,
                onTap: onBookmark,
              ),
              _SelectionAction(
                icon: Icons.note_alt_outlined,
                label: l10n.text('note'),
                onTap: onNote,
              ),
              if (onListen != null)
                _SelectionAction(
                  icon: Icons.headphones_rounded,
                  label: l10n.text('listen'),
                  onTap: onListen!,
                ),
              _SelectionAction(
                icon: Icons.copy_rounded,
                label: l10n.text('copy'),
                onTap: onCopy,
              ),
              _SelectionAction(
                icon: Icons.compare_arrows_rounded,
                label: l10n.text('compare'),
                onTap: onCompare,
              ),
            ],
          ),
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
  const _CompareVersion({
    required this.sourceId,
    required this.code,
    required this.title,
  });

  final String sourceId;
  final String code;
  final String title;
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
      padding: const EdgeInsets.all(3),
      child: Container(
        width: 32,
        height: 32,
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
    final l10n = context.l10n;
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(preview, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onDecrease,
            icon: const Icon(Icons.text_decrease_rounded),
            tooltip: l10n.text('shrink'),
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
            tooltip: l10n.text('enlarge'),
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
    final settings = AppSettingsScope.of(context);
    final languageCode = settings.readerUsesArabic
        ? 'ar'
        : translationById(settings.selectedQuranSourceId)?.languageCode ??
              Localizations.localeOf(context).languageCode;
    final displayName = localizedSurahName(surah.number, languageCode);
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        leading: SizedBox(
          width: 34,
          child: Text(
            '${surah.number}',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${surah.verseCount} ${context.l10n.text('verseUnit')}'),
        trailing: languageCode == 'ar'
            ? null
            : Text(
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
              context.l10n.text('translationPackError'),
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
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 44, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              l10n.text('searchHintTitle'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('searchHintBody'),
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
