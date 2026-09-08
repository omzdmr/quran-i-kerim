from pathlib import Path

ROOT = Path('.')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


# reader_audio_sheet.dart: replace controller implementation with disk-cache based player.
path = ROOT / 'lib/src/features/reader/reader_audio_sheet.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../data/translation_catalog.dart';\n",
    "import '../../data/translation_catalog.dart';\nimport 'reader_audio_cache.dart';\n",
    'audio cache import',
)
start = text.index('class ReaderAudioController extends ChangeNotifier {')
end = text.index('\nclass ReaderAudioSheet extends StatefulWidget {')
controller = r'''class ReaderAudioController extends ChangeNotifier {
  ReaderAudioController() {
    _subscriptions.addAll([
      _player.onPositionChanged.listen((value) {
        _position = value;
        notifyListeners();
      }),
      _player.onDurationChanged.listen((value) {
        _duration = value;
        notifyListeners();
      }),
      _player.onPlayerStateChanged.listen((value) {
        _playing = value == PlayerState.playing;
        notifyListeners();
      }),
      _player.onPlayerComplete.listen((_) => _onComplete()),
    ]);
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  ReaderAudioSourceConfig? _config;
  int _surah = 1;
  int _ayah = 1;
  int _verseCount = 1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _rate = 1.0;
  bool _playing = false;
  bool _loading = false;
  int _generation = 0;
  String? _loadedCacheKey;
  String? _error;

  ReaderAudioSourceConfig? get config => _config;
  int get surahNumber => _surah;
  int get currentAyah => _ayah;
  int get verseCount => _verseCount;
  Duration get position => _position;
  Duration get duration => _duration;
  double get rate => _rate;
  bool get isPlaying => _playing;
  bool get isLoading => _loading;
  bool get isConfigured => _config != null;
  String? get error => _error;

  Future<void> configure({
    required ReaderAudioSourceConfig config,
    required int surah,
    required int initialAyah,
    required int verseCount,
  }) async {
    final safeAyah = initialAyah.clamp(1, verseCount).toInt();
    final sourceChanged = _config?.id != config.id || _surah != surah;
    if (_playing && !sourceChanged) return;

    final targetChanged = sourceChanged || _ayah != safeAyah;
    _config = config;
    _surah = surah;
    _verseCount = verseCount;
    _error = null;

    if (targetChanged) {
      _generation++;
      await _player.stop();
      _ayah = safeAyah;
      _playing = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedCacheKey = null;
      notifyListeners();
    }

    unawaited(prefetchFrom(_ayah));
  }

  Future<void> prefetchFrom(int startAyah) async {
    final config = _config;
    if (config == null) return;
    await ReaderAudioCache.instance.prefetchWindow(
      sourceId: config.id,
      surah: _surah,
      startAyah: startAyah.clamp(1, _verseCount).toInt(),
      verseCount: _verseCount,
      urlForAyah: (ayah) => config.urlForVerse(_surah, ayah),
      windowSize: 4,
    );
  }

  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_loadedCacheKey != _cacheKeyForCurrent() || _position == Duration.zero) {
      await _playCurrent();
      return;
    }
    try {
      _error = null;
      await _player.resume();
      await _player.setPlaybackRate(_rate);
      unawaited(prefetchFrom(_ayah + 1));
    } catch (_) {
      _playing = false;
      _error = 'audio';
      notifyListeners();
    }
  }

  Future<void> previous() async {
    if (_config == null || _ayah <= 1) return;
    await _moveToAyah(_ayah - 1);
  }

  Future<void> next() async {
    if (_config == null || _ayah >= _verseCount) return;
    await _moveToAyah(_ayah + 1);
  }

  Future<void> _moveToAyah(int targetAyah) async {
    final wasPlaying = _playing;
    _generation++;
    await _player.stop();
    _ayah = targetAyah.clamp(1, _verseCount).toInt();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loadedCacheKey = null;
    notifyListeners();
    unawaited(prefetchFrom(_ayah));
    if (wasPlaying) await _playCurrent();
  }

  Future<void> seek(Duration value) => _player.seek(value);

  Future<void> setRate(double value) async {
    _rate = value.clamp(.5, 2.0).toDouble();
    if (_playing) await _player.setPlaybackRate(_rate);
    notifyListeners();
  }

  Future<void> stop() async {
    _generation++;
    await _player.stop();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loadedCacheKey = null;
    _loading = false;
    notifyListeners();
  }

  String _cacheKeyForCurrent() {
    final config = _config!;
    return ReaderAudioCache.instance.cacheKeyFor(config.id, _surah, _ayah);
  }

  Future<void> _playCurrent() async {
    final config = _config;
    if (config == null || _loading) return;
    final generation = _generation;
    final ayah = _ayah;
    final cacheKey = ReaderAudioCache.instance.cacheKeyFor(
      config.id,
      _surah,
      ayah,
    );
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final file = await ReaderAudioCache.instance.ensureCached(
        cacheKey: cacheKey,
        url: config.urlForVerse(_surah, ayah),
      );
      if (generation != _generation || ayah != _ayah) return;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedCacheKey = cacheKey;
      await _player.play(DeviceFileSource(file.path));
      await _player.setPlaybackRate(_rate);
      unawaited(prefetchFrom(_ayah + 1));
    } catch (_) {
      if (generation == _generation) {
        _playing = false;
        _loadedCacheKey = null;
        _error = 'audio';
        notifyListeners();
      }
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _onComplete() async {
    if (_ayah >= _verseCount) {
      _playing = false;
      _position = _duration;
      notifyListeners();
      return;
    }
    _ayah++;
    _loadedCacheKey = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playing = false;
    notifyListeners();
    await _playCurrent();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
'''
text = text[:start] + controller + text[end:]
path.write_text(text, encoding='utf-8')


# quran_reader_screen.dart: decouple scroll from audio, add follow mode and active verse styling.
path = ROOT / 'lib/src/features/reader/quran_reader_screen.dart'
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '  int? _lastAudioAyah;\n',
    '  int? _lastAudioAyah;\n  bool _audioFollowEnabled = true;\n  bool _manualReaderScroll = false;\n',
    'follow state fields',
)
text = replace_once(
    text,
    '''      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleScrollToAyah(_audioController.currentAyah);
        AppSettingsScope.of(context).saveReadingPosition(
          surah: _surahNumber,
          ayah: _audioController.currentAyah,
        );
      });''',
    '''      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });''',
    'audio follow listener',
)
text = replace_once(
    text,
    '''      final config = _audioConfig(settings);
      if (config != null) {
        _warmAudioAtAyah(config, _visibleAyah);
      }''',
    '''      final config = _audioConfig(settings);
      if (config != null) {
        _primeAudio(config, _visibleAyah);
      }''',
    'initial prime',
)
text = replace_once(
    text,
    '  void _scheduleScrollToAyah(int ayah, {int attempt = 0}) {',
    '  void _scheduleScrollToAyah(int ayah, {int attempt = 0, bool audioFollow = false}) {',
    'scroll signature',
)
text = replace_once(
    text,
    '        final desiredY = MediaQuery.paddingOf(context).top + 88;',
    '''        final desiredY = audioFollow
            ? MediaQuery.sizeOf(context).height * .28
            : MediaQuery.paddingOf(context).top + 88;''',
    'audio follow target',
)
text = replace_once(
    text,
    '          if (mounted) _scheduleScrollToAyah(ayah, attempt: attempt + 1);',
    '''          if (mounted) {
            _scheduleScrollToAyah(
              ayah,
              attempt: attempt + 1,
              audioFollow: audioFollow,
            );
          }''',
    'scroll retry args',
)
old_audio_methods = '''  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {
    await _warmAudioAtAyah(config, _visibleAyah);
  }

  Future<void> _warmAudioAtAyah(
    ReaderAudioSourceConfig config,
    int ayah,
  ) async {
    final surah = surahByNumber(_surahNumber);
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: ayah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
  }
'''
new_audio_methods = '''  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {
    final surah = surahByNumber(_surahNumber);
    final targetAyah = _audioController.isPlaying &&
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

  Future<void> _primeAudio(ReaderAudioSourceConfig config, int ayah) async {
    final surah = surahByNumber(_surahNumber);
    await _audioController.configure(
      config: config,
      surah: _surahNumber,
      initialAyah: ayah.clamp(1, surah.verseCount).toInt(),
      verseCount: surah.verseCount,
    );
  }
'''
text = replace_once(text, old_audio_methods, new_audio_methods, 'audio method split')
text = replace_once(
    text,
    '''  Future<void> _toggleAudio(ReaderAudioSourceConfig config) async {
    await _prepareAudio(config);
    await _audioController.toggle();
  }''',
    '''  Future<void> _toggleAudio(ReaderAudioSourceConfig config) async {
    await _prepareAudio(config);
    final wasPlaying = _audioController.isPlaying;
    await _audioController.toggle();
    if (!wasPlaying && _audioController.isPlaying && mounted) {
      setState(() {
        _audioFollowEnabled = true;
        _manualReaderScroll = false;
      });
      _scheduleScrollToAyah(
        _audioController.currentAyah,
        audioFollow: true,
      );
    }
  }''',
    'toggle follow',
)
text = replace_once(
    text,
    '''    final settings = AppSettingsScope.of(context);
    settings.saveReadingPosition(surah: _surahNumber, ayah: ayah);
    final config = _audioConfig(settings);
    if (config != null && !_audioController.isPlaying) {
      _warmAudioAtAyah(config, ayah);
    }''',
    '''    final settings = AppSettingsScope.of(context);
    settings.saveReadingPosition(surah: _surahNumber, ayah: ayah);''',
    'remove scroll audio configure',
)
# Mark manual scroll as follow-off while audio is playing.
text = replace_once(
    text,
    '''        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
          var shouldShow = notification.direction != ScrollDirection.reverse;''',
    '''        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
          if (notification.direction != ScrollDirection.idle &&
              _audioController.isPlaying) {
            _manualReaderScroll = true;
            if (_audioFollowEnabled) {
              setState(() => _audioFollowEnabled = false);
            }
          }
          var shouldShow = notification.direction != ScrollDirection.reverse;''',
    'manual scroll follow off',
)
# Pass active ayah into text widget.
text = replace_once(
    text,
    '''                selectedAyahs: _selectedAyahs,
                settings: settings,''',
    '''                selectedAyahs: _selectedAyahs,
                activeAudioAyah: _audioController.isPlaying &&
                        _audioController.surahNumber == _surahNumber
                    ? _audioController.currentAyah
                    : null,
                settings: settings,''',
    'active ayah prop',
)
# Add return-to-reading button above selection tray in Stack.
needle = '''          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: IgnorePointer('''
insert = '''          if (_audioController.isPlaying && !_audioFollowEnabled)
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
            child: IgnorePointer('''
text = replace_once(text, needle, insert, 'return to verse button')
# Widget field and constructor requirement.
text = replace_once(
    text,
    '''    required this.selectedAyahs,
    required this.settings,''',
    '''    required this.selectedAyahs,
    required this.activeAudioAyah,
    required this.settings,''',
    'active ayah ctor',
)
text = replace_once(
    text,
    '''  final Set<int> selectedAyahs;
  final AppSettings settings;''',
    '''  final Set<int> selectedAyahs;
  final int? activeAudioAyah;
  final AppSettings settings;''',
    'active ayah field',
)
# Active verse styling.
text = replace_once(
    text,
    '''      final selected = widget.selectedAyahs.contains(ayah);
      final highlight = widget.settings.highlightFor(widget.surahNumber, ayah);''',
    '''      final selected = widget.selectedAyahs.contains(ayah);
      final activeAudio = widget.activeAudioAyah == ayah;
      final highlight = widget.settings.highlightFor(widget.surahNumber, ayah);''',
    'active bool',
)
text = replace_once(
    text,
    '''        decoration: selected ? TextDecoration.underline : TextDecoration.none,
        decorationColor: scheme.onSurface.withValues(alpha: .88),
        decorationStyle: TextDecorationStyle.dotted,
        decorationThickness: 1.6,''',
    '''        decoration: activeAudio || selected
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: activeAudio
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: .88),
        decorationStyle: activeAudio
            ? TextDecorationStyle.solid
            : TextDecorationStyle.dotted,
        decorationThickness: activeAudio ? 2.5 : 1.6,''',
    'active underline style',
)
path.write_text(text, encoding='utf-8')
