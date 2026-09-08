from pathlib import Path

ROOT = Path('.')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


def replace_between(text: str, start: str, end: str, new: str, label: str) -> str:
    start_index = text.find(start)
    if start_index < 0:
        raise SystemExit(f'missing start target: {label}')
    end_index = text.find(end, start_index)
    if end_index < 0:
        raise SystemExit(f'missing end target: {label}')
    return text[:start_index] + new + text[end_index:]


# ---------------------------------------------------------------------------
# Prayer screen: GPS, local Hijri date, live compass, notification refresh.
# ---------------------------------------------------------------------------
path = ROOT / 'lib/src/features/prayer/presentation/prayer_screen.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:flutter_compass/flutter_compass.dart';\n",
    'prayer compass import',
)
text = replace_once(
    text,
    "import '../application/prayer_calculator.dart';\n",
    "import '../application/prayer_calculator.dart';\nimport '../application/prayer_location_service.dart';\nimport '../application/prayer_notification_service.dart';\n",
    'prayer services imports',
)
text = replace_once(
    text,
    "import '../domain/prayer_city_catalog.dart';\n",
    "import '../domain/hijri_date.dart';\nimport '../domain/prayer_city_catalog.dart';\n",
    'hijri import',
)
text = replace_once(
    text,
    "  bool _showTomorrow = false;\n",
    "  bool _showTomorrow = false;\n  bool _usingDeviceLocation = false;\n  bool _locating = false;\n",
    'prayer location state',
)
old_restore = '''  Future<void> _restoreState() async {
    final cityId = await PrayerPreferencesStore.loadCityId();
    final settings = await PrayerPreferencesStore.load();
    if (!mounted) return;
    setState(() {
      _city = prayerCityById(cityId);
      _prayerSettings = settings;
    });
  }

'''
new_restore = '''  Future<void> _restoreState() async {
    final cityId = await PrayerPreferencesStore.loadCityId();
    final settings = await PrayerPreferencesStore.load();
    if (!mounted) return;

    if (cityId == PrayerPreferencesStore.deviceLocationId) {
      final savedDevice = await PrayerPreferencesStore.loadDeviceLocation();
      if (!mounted) return;
      if (savedDevice != null) {
        setState(() {
          _city = _cityFromDevice(savedDevice);
          _usingDeviceLocation = true;
          _prayerSettings = settings;
        });
        return;
      }
    }

    setState(() {
      _city = prayerCityById(cityId);
      _usingDeviceLocation = false;
      _prayerSettings = settings;
    });
    if (cityId == null) {
      unawaited(_useCurrentLocation(silent: true, preferCached: true));
    }
  }

  PrayerCity _cityFromDevice(PrayerDeviceLocationSnapshot value) => PrayerCity(
        id: PrayerPreferencesStore.deviceLocationId,
        label: 'GPS',
        country: '',
        group: value.regionCode,
        location: value.location,
        defaultMethod: value.defaultMethod,
      );

  Future<void> _useCurrentLocation({
    bool silent = false,
    bool preferCached = false,
  }) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final result = await PrayerLocationService.current(
        preferCached: preferCached,
      );
      final saved = PrayerDeviceLocationSnapshot(
        location: result.location,
        defaultMethod: result.defaultMethod,
        regionCode: result.regionCode,
      );
      await PrayerPreferencesStore.saveDeviceLocation(saved);
      if (!mounted) return;
      setState(() {
        _city = _cityFromDevice(saved);
        _usingDeviceLocation = true;
        _showTomorrow = false;
      });
      await _refreshNotificationsForCurrentLocation();
      if (!mounted) return;
      HapticFeedback.selectionClick();
    } on PrayerLocationException catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationFailureMessage(error.failure))),
      );
    } catch (_) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('locationFailed'))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _locationFailureMessage(PrayerLocationFailure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      PrayerLocationFailure.serviceDisabled =>
        l10n.text('locationServicesDisabled'),
      PrayerLocationFailure.permissionDenied ||
      PrayerLocationFailure.permissionDeniedForever =>
        l10n.text('locationPermissionDenied'),
      PrayerLocationFailure.unavailable => l10n.text('locationFailed'),
    };
  }

  Future<void> _refreshNotificationsForCurrentLocation() async {
    if (!_prayerSettings.notificationsEnabled) return;
    await PrayerNotificationService.reschedule(
      location: _city.location,
      defaultMethod: _city.defaultMethod,
      settings: _prayerSettings,
    );
  }

'''
text = replace_once(text, old_restore, new_restore, 'prayer restore and GPS')
old_pick = '''  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(selectedCityId: _city.id),
    );

    if (picked == null || !mounted) return;
    await PrayerPreferencesStore.saveCityId(picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _showTomorrow = false;
    });
    HapticFeedback.selectionClick();
  }

'''
new_pick = '''  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(
        selectedCityId: _usingDeviceLocation ? null : _city.id,
      ),
    );

    if (picked == null || !mounted) return;
    await PrayerPreferencesStore.saveCityId(picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _usingDeviceLocation = false;
      _showTomorrow = false;
    });
    await _refreshNotificationsForCurrentLocation();
    if (!mounted) return;
    HapticFeedback.selectionClick();
  }

'''
text = replace_once(text, old_pick, new_pick, 'prayer city picker')
text = replace_once(
    text,
    "    final remaining = next.time.difference(_now);\n",
    "    final remaining = next.time.difference(_now);\n    final hijri = PrayerHijriDate.fromGregorian(\n      _now,\n      offsetDays: _prayerSettings.hijriOffsetDays,\n    );\n    final languageCode = Localizations.localeOf(context).languageCode;\n",
    'prayer hijri build data',
)
text = replace_once(
    text,
    '''        actions: [
          IconButton(
            onPressed: _openPrayerSettings,
''',
    '''        actions: [
          IconButton(
            onPressed: _locating ? null : () => _useCurrentLocation(),
            icon: _locating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: l10n.text('useCurrentLocation'),
          ),
          IconButton(
            onPressed: _openPrayerSettings,
''',
    'prayer GPS action',
)
text = replace_once(
    text,
    '''                        Text(
                          _city.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _city.country,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
''',
    '''                        Text(
                          _usingDeviceLocation
                              ? l10n.text('currentLocation')
                              : _city.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _usingDeviceLocation
                              ? '${_city.location.latitude.toStringAsFixed(3)}, ${_city.location.longitude.toStringAsFixed(3)} · ${_city.location.timeZoneId}'
                              : _city.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
''',
    'prayer location label',
)
text = replace_once(
    text,
    "          const SizedBox(height: 8),\n          Container(\n            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),\n",
    "          const SizedBox(height: 8),\n          Row(\n            children: [\n              Icon(Icons.calendar_today_outlined, size: 18, color: scheme.primary),\n              const SizedBox(width: 8),\n              Text(\n                hijri.format(languageCode),\n                style: const TextStyle(fontWeight: FontWeight.w800),\n              ),\n              const Spacer(),\n              Text(\n                l10n.text('hijriDate'),\n                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),\n              ),\n            ],\n          ),\n          const SizedBox(height: 12),\n          Container(\n            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),\n",
    'prayer Hijri row',
)
old_qibla_start = 'class QiblaInfoScreen extends StatelessWidget {'
old_qibla_end = 'class _PrayerTimeRow extends StatelessWidget {'
new_qibla = '''class QiblaInfoScreen extends StatelessWidget {
  const QiblaInfoScreen({
    required this.city,
    required this.qiblaDegrees,
    super.key,
  });

  final PrayerCity city;
  final double qiblaDegrees;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('qibla'))),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final rawDelta = heading == null
              ? qiblaDegrees
              : (qiblaDegrees - heading + 360) % 360;
          final signedDelta = rawDelta > 180 ? rawDelta - 360 : rawDelta;
          final aligned = heading != null && signedDelta.abs() <= 5;
          final angle = rawDelta * math.pi / 180;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Text(
                city.id == PrayerPreferencesStore.deviceLocationId
                    ? l10n.text('currentLocation')
                    : city.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heading == null
                    ? l10n.text('compassUnavailable')
                    : aligned
                        ? l10n.text('qiblaAligned')
                        : l10n.text('liveQibla'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: aligned ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainer,
                    border: Border.all(
                      color: aligned ? scheme.primary : scheme.outlineVariant,
                      width: aligned ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        top: 15,
                        child: Text(
                          'N',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      AnimatedRotation(
                        turns: rawDelta / 360,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 118,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                heading == null
                    ? '${qiblaDegrees.round()}°'
                    : '${signedDelta.abs().round()}°',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                heading == null
                    ? l10n.text('qiblaNorthDescription')
                    : l10n.text('liveQibla'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  l10n.text('qiblaCalibrationInfo'),
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

'''
text = replace_between(text, old_qibla_start, old_qibla_end, new_qibla, 'live qibla')
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Reader audio controller and sheet: explicit ayah chooser.
# ---------------------------------------------------------------------------
path = ROOT / 'lib/src/features/reader/reader_audio_sheet.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '''  Future<void> next() async {
    if (_config == null || _ayah >= _verseCount) return;
    await _moveToAyah(_ayah + 1);
  }

''',
    '''  Future<void> next() async {
    if (_config == null || _ayah >= _verseCount) return;
    await _moveToAyah(_ayah + 1);
  }

  Future<void> playAyah(int targetAyah) async {
    if (_config == null) return;
    final wasPlaying = _playing;
    await _moveToAyah(targetAyah.clamp(1, _verseCount).toInt());
    if (!wasPlaying) await _playCurrent();
  }

''',
    'audio play selected ayah',
)
text = replace_once(
    text,
    '''                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
''',
    '''                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    copy.chooseVerse,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.verseCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final ayah = index + 1;
                      return ChoiceChip(
                        label: Text('$ayah'),
                        selected: ayah == controller.currentAyah,
                        onSelected: (_) => controller.playAyah(ayah),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
''',
    'audio ayah list',
)
text = replace_once(
    text,
    "  String get hideButtons =>",
    "  String get chooseVerse => _pick('Ayet seç', 'Choose verse', 'اختر الآية', 'Ayə seç', 'Выбрать аят');\n  String get hideButtons =>",
    'audio choose verse copy',
)
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Reader: current-surah playback always primes ayah 1, chrome is overlay-only.
# ---------------------------------------------------------------------------
path = ROOT / 'lib/src/features/reader/quran_reader_screen.dart'
text = path.read_text(encoding='utf-8')
text = text.replace('  bool? _pendingReaderChromeVisible;\n', '', 1)
text = replace_once(
    text,
    '        _primeAudio(config, _visibleAyah);',
    '        _primeAudio(config, 1);',
    'reader initial audio prime',
)
old_prepare = '''  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {
    final surah = surahByNumber(_surahNumber);
    final targetAyah =
        _audioController.isPlaying &&
            _audioController.surahNumber == _surahNumber
        ? _audioController.currentAyah
        : _visibleAyah;
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: targetAyah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
  }

'''
new_prepare = '''  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {
    final surah = surahByNumber(_surahNumber);
    final sameSession = _audioController.isConfigured &&
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

'''
text = replace_once(text, old_prepare, new_prepare, 'reader play starts surah one')
old_chrome = '''  void _setReaderChromeVisible(bool visible) {
    if (!mounted || _readerChromeVisible == visible) return;
    final previousOffset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() => _readerChromeVisible = visible);
    if (previousOffset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      const chromeHeight = 69.0;
      final adjusted =
          previousOffset + (visible ? chromeHeight : -chromeHeight);
      _scrollController.jumpTo(
        adjusted.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }

'''
new_chrome = '''  void _setReaderChromeVisible(bool visible) {
    if (!mounted || _readerChromeVisible == visible) return;
    setState(() => _readerChromeVisible = visible);
  }

'''
text = replace_once(text, old_chrome, new_chrome, 'reader chrome no offset jump')
build_start = '  @override\n  Widget build(BuildContext context) {'
build_end = '  Widget _readerScrollView({'
new_build = '''  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final surah = surahByNumber(_surahNumber);
    final settings = AppSettingsScope.of(context);
    final audioConfig = _audioConfig(settings);
    final showTopChrome = _readerChromeVisible || _selectedAyahs.isNotEmpty;
    final showQuickAudio = _selectedAyahs.isEmpty &&
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
                final translations =
                    snapshot.data ?? const <String, String>{};
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

'''
text = replace_between(text, build_start, build_end, new_build, 'reader overlay build')
old_notification = '''      onNotification: (notification) {
        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
          if (notification.direction != ScrollDirection.idle &&
              _audioController.isPlaying) {
            _manualReaderScroll = true;
            if (_audioFollowEnabled) {
              setState(() => _audioFollowEnabled = false);
            }
          }
          var shouldShow = notification.direction != ScrollDirection.reverse;
          if (_scrollController.hasClients && _scrollController.offset < 18) {
            shouldShow = true;
          }
          _pendingReaderChromeVisible = shouldShow;
        }
        if (notification is ScrollEndNotification) {
          final pending = _pendingReaderChromeVisible;
          _pendingReaderChromeVisible = null;
          if (pending != null && pending != _readerChromeVisible) {
            _setReaderChromeVisible(pending);
          }
          _saveVisibleReadingPosition();
        }
        return false;
      },
'''
new_notification = '''      onNotification: (notification) {
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
'''
text = replace_once(text, old_notification, new_notification, 'reader scroll chrome notifications')
text = replace_once(
    text,
    '''          padding: EdgeInsets.fromLTRB(
            22,
            28,
            22,
''',
    '''          padding: EdgeInsets.fromLTRB(
            22,
            96,
            22,
''',
    'reader overlay top padding',
)
path.write_text(text, encoding='utf-8')


# ---------------------------------------------------------------------------
# Feature strings for the new prayer surfaces.
# ---------------------------------------------------------------------------
path = ROOT / 'lib/src/l10n/strings/feature_strings.dart'
text = path.read_text(encoding='utf-8')
insertions = {
    "    'groupSoutheastAsia': 'Güneydoğu Asya', 'groupCentralAsia': 'Orta Asya ve Kafkasya', 'groupEastAsia': 'Doğu Asya',\n": """    'groupSoutheastAsia': 'Güneydoğu Asya', 'groupCentralAsia': 'Orta Asya ve Kafkasya', 'groupEastAsia': 'Doğu Asya',
    'currentLocation': 'Mevcut konum', 'useCurrentLocation': 'Mevcut konumu kullan', 'refreshLocation': 'Konumu yenile',
    'locationPermissionDenied': 'Konum izni verilmedi. Şehir seçerek devam edebilirsiniz.', 'locationServicesDisabled': 'Konum servisleri kapalı.', 'locationFailed': 'Konum alınamadı. Şehir seçerek devam edebilirsiniz.',
    'gpsSource': 'GPS konumu', 'liveQibla': 'Canlı kıble yönü', 'compassUnavailable': 'Canlı pusula verisi alınamıyor; kuzeye göre kıble açısı gösteriliyor.', 'qiblaAligned': 'Kıble yönündesiniz',
    'prayerNotifications': 'Namaz bildirimleri', 'prayerNotificationsInfo': 'Seçtiğiniz vakitlerde cihazda yerel bildirim planlanır.', 'notificationPermissionDenied': 'Bildirim izni verilmedi.',
    'hijriDate': 'Hicri tarih', 'hijriDateOffset': 'Hicri tarih düzeltmesi', 'hijriDateOffsetInfo': 'Yerel hilal takviminiz farklıysa Hicri tarihi -2 ile +2 gün arasında düzeltin.', 'daysUnit': 'gün',
""",
    "    'groupSoutheastAsia': 'Southeast Asia', 'groupCentralAsia': 'Central Asia and Caucasus', 'groupEastAsia': 'East Asia',\n": """    'groupSoutheastAsia': 'Southeast Asia', 'groupCentralAsia': 'Central Asia and Caucasus', 'groupEastAsia': 'East Asia',
    'currentLocation': 'Current location', 'useCurrentLocation': 'Use current location', 'refreshLocation': 'Refresh location',
    'locationPermissionDenied': 'Location permission was not granted. You can continue by choosing a city.', 'locationServicesDisabled': 'Location services are turned off.', 'locationFailed': 'Could not get your location. You can continue by choosing a city.',
    'gpsSource': 'GPS location', 'liveQibla': 'Live Qibla direction', 'compassUnavailable': 'Live compass data is unavailable; showing the Qibla angle from north.', 'qiblaAligned': 'You are facing the Qibla',
    'prayerNotifications': 'Prayer notifications', 'prayerNotificationsInfo': 'Local notifications are scheduled on this device for the prayers you select.', 'notificationPermissionDenied': 'Notification permission was not granted.',
    'hijriDate': 'Hijri date', 'hijriDateOffset': 'Hijri date adjustment', 'hijriDateOffsetInfo': 'If your local moon-sighting calendar differs, adjust the Hijri date by -2 to +2 days.', 'daysUnit': 'days',
""",
    "    'groupSoutheastAsia': 'جنوب شرق آسيا', 'groupCentralAsia': 'آسيا الوسطى والقوقاز', 'groupEastAsia': 'شرق آسيا',\n": """    'groupSoutheastAsia': 'جنوب شرق آسيا', 'groupCentralAsia': 'آسيا الوسطى والقوقاز', 'groupEastAsia': 'شرق آسيا',
    'currentLocation': 'الموقع الحالي', 'useCurrentLocation': 'استخدام الموقع الحالي', 'refreshLocation': 'تحديث الموقع',
    'locationPermissionDenied': 'لم يتم منح إذن الموقع. يمكنك المتابعة باختيار مدينة.', 'locationServicesDisabled': 'خدمات الموقع متوقفة.', 'locationFailed': 'تعذر الحصول على موقعك. يمكنك المتابعة باختيار مدينة.',
    'gpsSource': 'موقع GPS', 'liveQibla': 'اتجاه القبلة المباشر', 'compassUnavailable': 'بيانات البوصلة المباشرة غير متاحة؛ يتم عرض زاوية القبلة من الشمال.', 'qiblaAligned': 'أنت باتجاه القبلة',
    'prayerNotifications': 'تنبيهات الصلاة', 'prayerNotificationsInfo': 'تتم جدولة تنبيهات محلية على الجهاز للصلوات التي تختارها.', 'notificationPermissionDenied': 'لم يتم منح إذن الإشعارات.',
    'hijriDate': 'التاريخ الهجري', 'hijriDateOffset': 'تعديل التاريخ الهجري', 'hijriDateOffsetInfo': 'إذا اختلف تقويم رؤية الهلال المحلي فعدّل التاريخ الهجري من -2 إلى +2 يوم.', 'daysUnit': 'يوم',
""",
    "    'groupSoutheastAsia': 'Cənub-Şərqi Asiya', 'groupCentralAsia': 'Mərkəzi Asiya və Qafqaz', 'groupEastAsia': 'Şərqi Asiya',\n": """    'groupSoutheastAsia': 'Cənub-Şərqi Asiya', 'groupCentralAsia': 'Mərkəzi Asiya və Qafqaz', 'groupEastAsia': 'Şərqi Asiya',
    'currentLocation': 'Cari məkan', 'useCurrentLocation': 'Cari məkanı istifadə et', 'refreshLocation': 'Məkanı yenilə',
    'locationPermissionDenied': 'Məkan icazəsi verilmədi. Şəhər seçərək davam edə bilərsiniz.', 'locationServicesDisabled': 'Məkan xidmətləri söndürülüb.', 'locationFailed': 'Məkan alınmadı. Şəhər seçərək davam edə bilərsiniz.',
    'gpsSource': 'GPS məkanı', 'liveQibla': 'Canlı Qiblə istiqaməti', 'compassUnavailable': 'Canlı kompas məlumatı yoxdur; Qiblənin şimala görə bucağı göstərilir.', 'qiblaAligned': 'Qibləyə yönəlmisiniz',
    'prayerNotifications': 'Namaz bildirişləri', 'prayerNotificationsInfo': 'Seçdiyiniz namazlar üçün cihazda yerli bildirişlər planlanır.', 'notificationPermissionDenied': 'Bildiriş icazəsi verilmədi.',
    'hijriDate': 'Hicri tarix', 'hijriDateOffset': 'Hicri tarix düzəlişi', 'hijriDateOffsetInfo': 'Yerli hilal təqvimi fərqlidirsə Hicri tarixi -2 ilə +2 gün arasında düzəldin.', 'daysUnit': 'gün',
""",
    "    'groupSoutheastAsia': 'Юго-Восточная Азия', 'groupCentralAsia': 'Центральная Азия и Кавказ', 'groupEastAsia': 'Восточная Азия',\n": """    'groupSoutheastAsia': 'Юго-Восточная Азия', 'groupCentralAsia': 'Центральная Азия и Кавказ', 'groupEastAsia': 'Восточная Азия',
    'currentLocation': 'Текущее местоположение', 'useCurrentLocation': 'Использовать текущее местоположение', 'refreshLocation': 'Обновить местоположение',
    'locationPermissionDenied': 'Разрешение на геолокацию не выдано. Можно продолжить, выбрав город.', 'locationServicesDisabled': 'Службы геолокации отключены.', 'locationFailed': 'Не удалось определить местоположение. Можно продолжить, выбрав город.',
    'gpsSource': 'GPS-местоположение', 'liveQibla': 'Кибла в реальном времени', 'compassUnavailable': 'Данные компаса недоступны; показан угол Киблы относительно севера.', 'qiblaAligned': 'Вы направлены к Кибле',
    'prayerNotifications': 'Уведомления о намазе', 'prayerNotificationsInfo': 'Для выбранных намазов на устройстве планируются локальные уведомления.', 'notificationPermissionDenied': 'Разрешение на уведомления не выдано.',
    'hijriDate': 'Дата по Хиджре', 'hijriDateOffset': 'Поправка даты по Хиджре', 'hijriDateOffsetInfo': 'Если местный лунный календарь отличается, скорректируйте дату от -2 до +2 дней.', 'daysUnit': 'дн.',
""",
}
for old, new in insertions.items():
    text = replace_once(text, old, new, f'l10n insertion {old[:30]}')
path.write_text(text, encoding='utf-8')
