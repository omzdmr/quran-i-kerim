import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/quran_audio_catalog.dart';
import '../../data/translation_catalog.dart';
import 'reader_audio_cache.dart';

class ReaderAudioSourceConfig {
  const ReaderAudioSourceConfig({
    required this.id,
    required this.code,
    required this.title,
    required this.urlForVerse,
  });

  final String id;
  final String code;
  final String title;
  final String Function(int surah, int ayah) urlForVerse;
}

ReaderAudioSourceConfig? readerAudioConfigFor(String sourceId) {
  final audio = primaryQuranAudioForSource(sourceId);
  if (audio == null) return null;

  if (audio.kind == QuranAudioKind.recitation) {
    return ReaderAudioSourceConfig(
      id: audio.id,
      code: audio.code,
      title: audio.title,
      urlForVerse: (surah, ayah) =>
          quran.getAudioURLByVerse(surah, ayah, bitrate: 64),
    );
  }

  final info = translationById(sourceId);
  if (info == null || info.sourceKey != 'english_rwwad') return null;
  return ReaderAudioSourceConfig(
    id: audio.id,
    code: audio.code,
    title: audio.title,
    urlForVerse: (surah, ayah) {
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      return 'https://d.quranenc.com/data/audio/${info.sourceKey}/$s$a.mp3';
    },
  );
}

class ReaderAudioController extends ChangeNotifier {
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
    if (_loadedCacheKey != _cacheKeyForCurrent() ||
        _position == Duration.zero) {
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

class ReaderAudioSheet extends StatefulWidget {
  const ReaderAudioSheet({
    required this.controller,
    required this.surahLabel,
    required this.quickControlsVisible,
    required this.onQuickControlsVisibilityChanged,
    super.key,
  });

  final ReaderAudioController controller;
  final String surahLabel;
  final bool quickControlsVisible;
  final ValueChanged<bool> onQuickControlsVisibilityChanged;

  @override
  State<ReaderAudioSheet> createState() => _ReaderAudioSheetState();
}

class _ReaderAudioSheetState extends State<ReaderAudioSheet> {
  late bool _quickControlsVisible = widget.quickControlsVisible;

  @override
  Widget build(BuildContext context) {
    final copy = _AudioCopy(Localizations.localeOf(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final durationMs = controller.duration.inMilliseconds;
          final positionMs = controller.position.inMilliseconds.clamp(
            0,
            durationMs <= 0 ? 0 : durationMs,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.surahLabel} ${controller.surahNumber}:${controller.currentAyah}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${controller.config?.code ?? ''} · ${controller.config?.title ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: controller.currentAyah > 1
                          ? controller.previous
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded, size: 30),
                      tooltip: copy.previous,
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: IconButton.filled(
                        onPressed: controller.toggle,
                        icon: Icon(
                          controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                        ),
                        tooltip: controller.isPlaying ? copy.pause : copy.play,
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton.filledTonal(
                      onPressed: controller.currentAyah < controller.verseCount
                          ? controller.next
                          : null,
                      icon: const Icon(Icons.skip_next_rounded, size: 30),
                      tooltip: copy.next,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Slider(
                  value: durationMs <= 0 ? 0 : positionMs.toDouble(),
                  max: durationMs <= 0 ? 1 : durationMs.toDouble(),
                  onChanged: durationMs <= 0
                      ? null
                      : (value) => controller.seek(
                          Duration(milliseconds: value.round()),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(_formatDuration(controller.position)),
                      const Spacer(),
                      Text(_formatDuration(controller.duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PopupMenuButton<double>(
                      onSelected: controller.setRate,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: .75, child: Text('0.75x')),
                        PopupMenuItem(value: 1.0, child: Text('1x')),
                        PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        PopupMenuItem(value: 2.0, child: Text('2x')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${controller.rate.toStringAsFixed(controller.rate % 1 == 0 ? 0 : 2)}x',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _quickControlsVisible = !_quickControlsVisible;
                        });
                        widget.onQuickControlsVisibilityChanged(
                          _quickControlsVisible,
                        );
                      },
                      icon: Icon(
                        _quickControlsVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        _quickControlsVisible
                            ? copy.hideButtons
                            : copy.showButtons,
                      ),
                    ),
                  ],
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    copy.audioError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _AudioCopy {
  const _AudioCopy(this.languageCode);
  final String languageCode;

  String get play => _pick('Oynat', 'Play', 'تشغيل', 'Oxut', 'Воспроизвести');
  String get pause =>
      _pick('Duraklat', 'Pause', 'إيقاف مؤقت', 'Pauza', 'Пауза');
  String get previous => _pick(
    'Önceki ayet',
    'Previous verse',
    'الآية السابقة',
    'Əvvəlki ayə',
    'Предыдущий аят',
  );
  String get next => _pick(
    'Sonraki ayet',
    'Next verse',
    'الآية التالية',
    'Növbəti ayə',
    'Следующий аят',
  );
  String get hideButtons => _pick(
    'Tuşları gizle',
    'Hide controls',
    'إخفاء الأزرار',
    'Düymələri gizlət',
    'Скрыть кнопки',
  );
  String get showButtons => _pick(
    'Tuşları göster',
    'Show controls',
    'إظهار الأزرار',
    'Düymələri göstər',
    'Показать кнопки',
  );
  String get audioError => _pick(
    'Ses açılamadı. Bağlantıyı kontrol edip yeniden deneyin.',
    'Audio could not be opened. Check the connection and try again.',
    'تعذر تشغيل الصوت. تحقق من الاتصال وحاول مجدداً.',
    'Səs açıla bilmədi. Bağlantını yoxlayıb yenidən cəhd edin.',
    'Не удалось открыть аудио. Проверьте соединение и попробуйте снова.',
  );

  String _pick(String tr, String en, String ar, String az, String ru) =>
      switch (languageCode) {
        'tr' => tr,
        'ar' => ar,
        'az' => az,
        'ru' => ru,
        _ => en,
      };
}
