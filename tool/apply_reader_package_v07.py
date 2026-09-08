from pathlib import Path
import re

ROOT = Path('.')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


def write(path: str, text: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding='utf-8')


# 1) Local Quran metadata wrapper.
write(
    'lib/src/data/quran_verse_metadata.dart',
    """import 'package:quran/quran.dart' as quran;\n\nclass QuranVerseMetadata {\n  const QuranVerseMetadata({\n    required this.surah,\n    required this.ayah,\n    required this.juz,\n    required this.page,\n    required this.isSajdah,\n  });\n\n  final int surah;\n  final int ayah;\n  final int juz;\n  final int page;\n  final bool isSajdah;\n}\n\nQuranVerseMetadata quranVerseMetadata(int surah, int ayah) {\n  return QuranVerseMetadata(\n    surah: surah,\n    ayah: ayah,\n    juz: quran.getJuzNumber(surah, ayah),\n    page: quran.getPageNumber(surah, ayah),\n    isSajdah: quran.isSajdahVerse(surah, ayah),\n  );\n}\n""",
)

# 2) Reader: raw-pointer horizontal swipe (does not join Flutter gesture arena),
#    delayed chrome changes until scroll end, warm audio around visible ayah,
#    and show juz/page/sajdah metadata.
reader_path = ROOT / 'lib/src/features/reader/quran_reader_screen.dart'
reader = reader_path.read_text(encoding='utf-8')
reader = replace_once(
    reader,
    "import '../../data/surah_catalog.dart';\n",
    "import '../../data/quran_verse_metadata.dart';\nimport '../../data/surah_catalog.dart';\n",
    'reader metadata import',
)
reader = replace_once(
    reader,
    "  bool _audioQuickControlsVisible = true;\n  double _horizontalDragDistance = 0;\n  int? _lastAudioAyah;\n",
    "  bool _audioQuickControlsVisible = true;\n  double _horizontalDragDistance = 0;\n  double _verticalPointerDistance = 0;\n  bool? _pendingReaderChromeVisible;\n  int _visibleAyah = 1;\n  int? _lastAudioAyah;\n",
    'reader fields',
)
reader = replace_once(
    reader,
    "    _anchorAyah = settings.lastAyah.clamp(1, surah.verseCount).toInt();\n    _didRestorePosition = true;\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      _handleReaderRequest();\n      _scheduleScrollToAyah(_anchorAyah);\n    });\n",
    "    _anchorAyah = settings.lastAyah.clamp(1, surah.verseCount).toInt();\n    _visibleAyah = _anchorAyah;\n    _didRestorePosition = true;\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      _handleReaderRequest();\n      _scheduleScrollToAyah(_anchorAyah);\n      final config = _audioConfig(settings);\n      if (config != null) {\n        _warmAudioAtAyah(config, _visibleAyah);\n      }\n    });\n",
    'restore warm audio',
)
reader = replace_once(
    reader,
    "      _surahNumber = surah.number;\n      _anchorAyah = safeAyah;\n      _selectedAyahs.clear();\n",
    "      _surahNumber = surah.number;\n      _anchorAyah = safeAyah;\n      _visibleAyah = safeAyah;\n      _selectedAyahs.clear();\n",
    'jump visible ayah',
)
reader = replace_once(
    reader,
    "      _surahNumber = surah.number;\n      _anchorAyah = 1;\n      _selectedAyahs.clear();\n",
    "      _surahNumber = surah.number;\n      _anchorAyah = 1;\n      _visibleAyah = 1;\n      _selectedAyahs.clear();\n",
    'open surah visible ayah',
)
reader = replace_once(
    reader,
    "  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {\n    final surah = surahByNumber(_surahNumber);\n    final settings = AppSettingsScope.of(context);\n    await _audioController.configure(\n      config: config,\n      surah: _surahNumber,\n      initialAyah: settings.lastAyah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n    );\n  }\n",
    "  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {\n    await _warmAudioAtAyah(config, _visibleAyah);\n  }\n\n  Future<void> _warmAudioAtAyah(\n    ReaderAudioSourceConfig config,\n    int ayah,\n  ) async {\n    final surah = surahByNumber(_surahNumber);\n    await _audioController.configure(\n      config: config,\n      surah: _surahNumber,\n      initialAyah: ayah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n    );\n  }\n",
    'audio prepare helper',
)

old_scroll_open = """    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
          var shouldShow = notification.direction != ScrollDirection.reverse;
          if (_scrollController.hasClients && _scrollController.offset < 18) {
            shouldShow = true;
          }
          if (shouldShow != _readerChromeVisible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _selectedAyahs.isNotEmpty) return;
              if (_readerChromeVisible != shouldShow) {
                _setReaderChromeVisible(shouldShow);
              }
            });
          }
        }
        if (notification is ScrollEndNotification) {
          _saveVisibleReadingPosition();
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
        onHorizontalDragUpdate: (details) {
          _horizontalDragDistance += details.primaryDelta ?? 0;
        },
        onHorizontalDragEnd: _handleHorizontalReaderSwipe,
        child: SingleChildScrollView(
"""
new_scroll_open = """    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification && _selectedAyahs.isEmpty) {
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
"""
reader = replace_once(reader, old_scroll_open, new_scroll_open, 'scroll gesture wrapper')
reader = replace_once(
    reader,
    "              _surahHeader(surah, settings),\n",
    "              _surahHeader(surah, settings),\n              _verseMetadataStrip(),\n",
    'metadata strip placement',
)

old_swipe = """  void _handleHorizontalReaderSwipe(DragEndDetails details) {
    if (_selectedAyahs.isNotEmpty) return;
    final distance = _horizontalDragDistance;
    _horizontalDragDistance = 0;
    final velocity = details.primaryVelocity ?? 0;
    if (distance.abs() < 72) return;
    if (velocity.abs() < 250 && distance.abs() < 110) return;
    if (distance < 0 && _surahNumber < 114) {
      _openSurahAtStart(_surahNumber + 1);
    } else if (distance > 0 && _surahNumber > 1) {
      _openSurahAtStart(_surahNumber - 1);
    }
  }

  void _saveVisibleReadingPosition() {
    if (!mounted) return;
    final targetY = MediaQuery.paddingOf(context).top + 100;
    final ayah = _textKey.currentState?.ayahClosestToGlobalY(targetY);
    if (ayah == null) return;
    AppSettingsScope.of(context)
        .saveReadingPosition(surah: _surahNumber, ayah: ayah);
  }
"""
new_swipe = """  Widget _verseMetadataStrip() {
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
        label('Secde ayeti', 'Sajdah verse', 'آية سجدة', 'Səcdə ayəsi', 'Аят саджда'),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    final config = _audioConfig(settings);
    if (config != null && !_audioController.isPlaying) {
      _warmAudioAtAyah(config, ayah);
    }
  }
"""
reader = replace_once(reader, old_swipe, new_swipe, 'swipe + metadata + visible position')
reader_path.write_text(reader, encoding='utf-8')

# 3) Audio: 64 kbps Arabic verse source, eager current verse prepare,
#    plus a second prepared player for the next verse.
audio_path = ROOT / 'lib/src/features/reader/reader_audio_sheet.dart'
audio = audio_path.read_text(encoding='utf-8')
audio = replace_once(
    audio,
    "      urlForVerse: (surah, ayah) => quran.getAudioURLByVerse(surah, ayah),\n",
    "      urlForVerse: (surah, ayah) =>\n          quran.getAudioURLByVerse(surah, ayah, bitrate: 64),\n",
    'arabic 64kbps url',
)

controller_pattern = re.compile(
    r'class ReaderAudioController extends ChangeNotifier \{.*?\n\}\n\nclass ReaderAudioSheet',
    re.S,
)
new_controller = r'''class ReaderAudioController extends ChangeNotifier {
  ReaderAudioController() {
    _bindPlayer(_activePlayer);
    _bindPlayer(_standbyPlayer);
  }

  AudioPlayer _activePlayer = AudioPlayer();
  AudioPlayer _standbyPlayer = AudioPlayer();
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
  bool _preparingCurrent = false;
  int _generation = 0;
  String? _loadedUrl;
  int? _preparedStandbyAyah;
  String? _error;

  ReaderAudioSourceConfig? get config => _config;
  int get surahNumber => _surah;
  int get currentAyah => _ayah;
  int get verseCount => _verseCount;
  Duration get position => _position;
  Duration get duration => _duration;
  double get rate => _rate;
  bool get isPlaying => _playing;
  bool get isConfigured => _config != null;
  String? get error => _error;

  void _bindPlayer(AudioPlayer player) {
    _subscriptions.addAll([
      player.onPositionChanged.listen((value) {
        if (!identical(player, _activePlayer)) return;
        _position = value;
        notifyListeners();
      }),
      player.onDurationChanged.listen((value) {
        if (!identical(player, _activePlayer)) return;
        _duration = value;
        notifyListeners();
      }),
      player.onPlayerStateChanged.listen((value) {
        if (!identical(player, _activePlayer)) return;
        _playing = value == PlayerState.playing;
        notifyListeners();
      }),
      player.onPlayerComplete.listen((_) {
        if (identical(player, _activePlayer)) {
          _onComplete(player);
        }
      }),
    ]);
  }

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
      await _activePlayer.stop();
      await _standbyPlayer.stop();
      _ayah = safeAyah;
      _playing = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedUrl = null;
      _preparedStandbyAyah = null;
      notifyListeners();
    }

    if (_loadedUrl == null && !_preparingCurrent) {
      await _prepareCurrent();
    } else {
      _prepareNext();
    }
  }

  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _activePlayer.pause();
      return;
    }
    if (_loadedUrl == null) {
      await _prepareCurrent();
    }
    if (_loadedUrl == null) return;
    try {
      _error = null;
      await _activePlayer.resume();
      await _activePlayer.setPlaybackRate(_rate);
      _prepareNext();
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
    if (_preparedStandbyAyah == _ayah + 1) {
      await _usePreparedNext();
      return;
    }
    await _moveToAyah(_ayah + 1);
  }

  Future<void> _moveToAyah(int targetAyah) async {
    final wasPlaying = _playing;
    _generation++;
    await _activePlayer.stop();
    await _standbyPlayer.stop();
    _ayah = targetAyah.clamp(1, _verseCount).toInt();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loadedUrl = null;
    _preparedStandbyAyah = null;
    notifyListeners();
    await _prepareCurrent();
    if (wasPlaying && _loadedUrl != null) {
      await _activePlayer.resume();
      await _activePlayer.setPlaybackRate(_rate);
      _prepareNext();
    }
  }

  Future<void> seek(Duration value) => _activePlayer.seek(value);

  Future<void> setRate(double value) async {
    _rate = value.clamp(.5, 2.0).toDouble();
    if (_playing) await _activePlayer.setPlaybackRate(_rate);
    notifyListeners();
  }

  Future<void> stop() async {
    _generation++;
    await _activePlayer.stop();
    await _standbyPlayer.stop();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loadedUrl = null;
    _preparedStandbyAyah = null;
    notifyListeners();
  }

  Future<void> _prepareCurrent() async {
    final config = _config;
    if (config == null || _preparingCurrent) return;
    final generation = _generation;
    final url = config.urlForVerse(_surah, _ayah);
    _preparingCurrent = true;
    try {
      _error = null;
      await _activePlayer.setSource(UrlSource(url));
      if (generation != _generation) return;
      _loadedUrl = url;
      notifyListeners();
      _prepareNext();
    } catch (_) {
      if (generation != _generation) return;
      _loadedUrl = null;
      _error = 'audio';
      notifyListeners();
    } finally {
      _preparingCurrent = false;
    }
  }

  Future<void> _prepareNext() async {
    final config = _config;
    if (config == null || _ayah >= _verseCount) {
      _preparedStandbyAyah = null;
      return;
    }
    final nextAyah = _ayah + 1;
    if (_preparedStandbyAyah == nextAyah) return;
    final generation = _generation;
    try {
      await _standbyPlayer.stop();
      await _standbyPlayer.setSource(
        UrlSource(config.urlForVerse(_surah, nextAyah)),
      );
      if (generation != _generation || nextAyah != _ayah + 1) return;
      _preparedStandbyAyah = nextAyah;
    } catch (_) {
      if (generation == _generation) {
        _preparedStandbyAyah = null;
      }
    }
  }

  Future<void> _usePreparedNext() async {
    if (_preparedStandbyAyah != _ayah + 1) {
      await _moveToAyah(_ayah + 1);
      return;
    }
    final wasPlaying = _playing;
    final oldActive = _activePlayer;
    _activePlayer = _standbyPlayer;
    _standbyPlayer = oldActive;
    _ayah++;
    _loadedUrl = _config?.urlForVerse(_surah, _ayah);
    _preparedStandbyAyah = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playing = false;
    notifyListeners();
    if (wasPlaying) {
      await _activePlayer.resume();
      await _activePlayer.setPlaybackRate(_rate);
    }
    _prepareNext();
  }

  Future<void> _onComplete(AudioPlayer completedPlayer) async {
    if (!identical(completedPlayer, _activePlayer)) return;
    if (_ayah >= _verseCount) {
      _playing = false;
      _position = _duration;
      notifyListeners();
      return;
    }
    if (_preparedStandbyAyah == _ayah + 1) {
      final oldActive = _activePlayer;
      _activePlayer = _standbyPlayer;
      _standbyPlayer = oldActive;
      _ayah++;
      _loadedUrl = _config?.urlForVerse(_surah, _ayah);
      _preparedStandbyAyah = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _playing = false;
      notifyListeners();
      try {
        await _activePlayer.resume();
        await _activePlayer.setPlaybackRate(_rate);
        _prepareNext();
        return;
      } catch (_) {
        _loadedUrl = null;
      }
    }
    await _moveToAyah(_ayah + 1);
    if (_loadedUrl != null) {
      await _activePlayer.resume();
      await _activePlayer.setPlaybackRate(_rate);
      _prepareNext();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _activePlayer.dispose();
    _standbyPlayer.dispose();
    super.dispose();
  }
}

class ReaderAudioSheet'''
audio, count = controller_pattern.subn(new_controller, audio, count=1)
if count != 1:
    raise SystemExit('missing patch target: reader audio controller')
audio_path.write_text(audio, encoding='utf-8')

# 4) Extend existing test file already included by CI.
test_path = ROOT / 'test/surah_localization_test.dart'
test = test_path.read_text(encoding='utf-8')
test = replace_once(
    test,
    "import 'package:flutter_test/flutter_test.dart';\n",
    "import 'package:flutter_test/flutter_test.dart';\nimport 'package:quran_i_kerim/src/data/quran_verse_metadata.dart';\n",
    'metadata test import',
)
test = replace_once(
    test,
    "  test('search aliases include active and cross-language names', () {\n",
    "  test('quran metadata exposes local juz page and sajdah data', () {\n    final first = quranVerseMetadata(1, 1);\n    expect(first.juz, 1);\n    expect(first.page, 1);\n    expect(first.isSajdah, isFalse);\n\n    final sajdah = quranVerseMetadata(96, 19);\n    expect(sajdah.juz, inInclusiveRange(1, 30));\n    expect(sajdah.page, inInclusiveRange(1, 604));\n    expect(sajdah.isSajdah, isTrue);\n  });\n\n  test('search aliases include active and cross-language names', () {\n",
    'metadata unit test',
)
test_path.write_text(test, encoding='utf-8')

print('reader package v07 patch applied')
