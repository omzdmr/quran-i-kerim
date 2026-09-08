import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/quran_audio_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../settings/app_settings.dart';
import 'offline_audio_manager.dart';
import 'reader_audio_cache.dart';

class ReaderAudioSourceConfig {
  const ReaderAudioSourceConfig({
    required this.id,
    required this.cacheId,
    required this.sourceId,
    required this.code,
    required this.title,
    required this.urlForVerse,
    required this.availableBitrates,
    this.bitrate,
  });

  final String id;
  final String cacheId;
  final String sourceId;
  final String code;
  final String title;
  final int? bitrate;
  final List<int> availableBitrates;
  final String Function(int surah, int ayah) urlForVerse;
}

int _absoluteVerseNumber(int surah, int ayah) {
  var value = ayah;
  for (var previous = 1; previous < surah; previous++) {
    value += quran.getVerseCount(previous);
  }
  return value;
}

ReaderAudioSourceConfig? readerAudioConfigFor(
  String sourceId, {
  String? audioId,
  int? bitrate,
}) {
  final available = quranAudioForSource(sourceId);
  if (available.isEmpty) return null;
  var audio = available.first;
  if (audioId != null) {
    for (final candidate in available) {
      if (candidate.id == audioId) {
        audio = candidate;
        break;
      }
    }
  }

  final bitrates = quranAudioBitrates(audio);
  final selectedBitrate = bitrate != null && bitrates.contains(bitrate)
      ? bitrate
      : audio.bitrate;
  return ReaderAudioSourceConfig(
    id: audio.id,
    cacheId: selectedBitrate == null
        ? audio.id
        : '${audio.id}_$selectedBitrate',
    sourceId: sourceId,
    code: audio.code,
    title: audio.style == null
        ? audio.title
        : '${audio.title} · ${audio.style}',
    bitrate: selectedBitrate,
    availableBitrates: bitrates,
    urlForVerse: (surah, ayah) {
      if (audio.provider == QuranAudioProvider.quranEnc) {
        final s = surah.toString().padLeft(3, '0');
        final a = ayah.toString().padLeft(3, '0');
        return 'https://d.quranenc.com/data/audio/${audio.providerKey}/$s$a.mp3';
      }
      final absolute = _absoluteVerseNumber(surah, ayah);
      final resolvedBitrate = selectedBitrate ?? audio.bitrate ?? 128;
      return 'https://cdn.islamic.network/quran/audio/$resolvedBitrate/${audio.providerKey}/$absolute.mp3';
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
  bool _continueAfterSurah = true;
  Future<bool> Function()? _onRequestNextSurah;
  Timer? _sleepTimer;
  int? _sleepMinutes;
  bool _sleepAtSurahEnd = false;

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
  int? get sleepMinutes => _sleepMinutes;
  bool get sleepAtSurahEnd => _sleepAtSurahEnd;

  Future<void> configure({
    required ReaderAudioSourceConfig config,
    required int surah,
    required int initialAyah,
    required int verseCount,
    bool continueAfterSurah = true,
    Future<bool> Function()? onRequestNextSurah,
  }) async {
    final safeAyah = initialAyah.clamp(1, verseCount).toInt();
    final sourceChanged = _config?.cacheId != config.cacheId || _surah != surah;
    if (_playing && !sourceChanged) return;

    final targetChanged = sourceChanged || _ayah != safeAyah;
    _config = config;
    _surah = surah;
    _verseCount = verseCount;
    _continueAfterSurah = continueAfterSurah;
    _onRequestNextSurah = onRequestNextSurah;
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
      sourceId: config.cacheId,
      surah: _surah,
      startAyah: startAyah.clamp(1, _verseCount).toInt(),
      verseCount: _verseCount,
      urlForAyah: (ayah) => config.urlForVerse(_surah, ayah),
      isOfflineAvailable: (ayah) =>
          OfflineAudioManager.instance.isVerseDownloaded(
            storageKey: config.cacheId,
            surah: _surah,
            ayah: ayah,
          ),
      windowSize: 4,
    );
  }

  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    final completedSurah =
        _ayah >= _verseCount &&
        _duration > Duration.zero &&
        _position >= _duration;
    if (completedSurah) {
      await _moveToAyah(1);
      await _playCurrent();
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

  Future<void> playAyah(int targetAyah) async {
    if (_config == null) return;
    final wasPlaying = _playing;
    await _moveToAyah(targetAyah.clamp(1, _verseCount).toInt());
    if (!wasPlaying) await _playCurrent();
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

  void setContinueAfterSurah(bool value) {
    _continueAfterSurah = value;
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutes = null;
    _sleepAtSurahEnd = false;
    if (duration != null && duration > Duration.zero) {
      _sleepMinutes = duration.inMinutes;
      _sleepTimer = Timer(duration, () {
        _sleepTimer = null;
        _sleepMinutes = null;
        _sleepAtSurahEnd = false;
        unawaited(stop());
      });
    }
    notifyListeners();
  }

  void setSleepAtSurahEnd() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutes = null;
    _sleepAtSurahEnd = true;
    notifyListeners();
  }

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
    return ReaderAudioCache.instance.cacheKeyFor(config.cacheId, _surah, _ayah);
  }

  Future<void> _playCurrent() async {
    final config = _config;
    if (config == null || _loading) return;
    final generation = _generation;
    final ayah = _ayah;
    final cacheKey = ReaderAudioCache.instance.cacheKeyFor(
      config.cacheId,
      _surah,
      ayah,
    );
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final offline = await OfflineAudioManager.instance.offlineFile(
        storageKey: config.cacheId,
        surah: _surah,
        ayah: ayah,
      );
      final file =
          offline ??
          await ReaderAudioCache.instance.ensureCached(
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
      if (_sleepAtSurahEnd) {
        _sleepAtSurahEnd = false;
        _sleepMinutes = null;
        _playing = false;
        _position = _duration;
        notifyListeners();
        return;
      }
      if (_continueAfterSurah && _onRequestNextSurah != null) {
        final handled = await _onRequestNextSurah!();
        if (handled) return;
      }
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
    _sleepTimer?.cancel();
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
    required this.availableSources,
    required this.onSourceSelected,
    required this.onBitrateSelected,
    super.key,
  });

  final ReaderAudioController controller;
  final String surahLabel;
  final bool quickControlsVisible;
  final ValueChanged<bool> onQuickControlsVisibilityChanged;
  final List<QuranAudioInfo> availableSources;
  final Future<void> Function(String audioId) onSourceSelected;
  final Future<void> Function(int bitrate) onBitrateSelected;

  @override
  State<ReaderAudioSheet> createState() => _ReaderAudioSheetState();
}

class _ReaderAudioSheetState extends State<ReaderAudioSheet> {
  late bool _quickControlsVisible = widget.quickControlsVisible;
  String? _statsKey;
  Future<AudioSurahStats>? _statsFuture;
  bool _installingText = false;
  double _textProgress = 0;

  @override
  void initState() {
    super.initState();
    OfflineAudioManager.instance.addListener(_handleOfflineChanged);
  }

  @override
  void dispose() {
    OfflineAudioManager.instance.removeListener(_handleOfflineChanged);
    super.dispose();
  }

  void _handleOfflineChanged() {
    if (mounted) setState(() {});
  }

  Future<AudioSurahStats> _statsFor(ReaderAudioSourceConfig config) {
    final key =
        '${config.cacheId}|${widget.controller.surahNumber}|${widget.controller.verseCount}';
    if (_statsKey != key || _statsFuture == null) {
      _statsKey = key;
      _statsFuture = OfflineAudioManager.instance.surahStats(
        storageKey: config.cacheId,
        surah: widget.controller.surahNumber,
        verseCount: widget.controller.verseCount,
      );
    }
    return _statsFuture!;
  }

  void _refreshStats() {
    _statsKey = null;
    _statsFuture = null;
    if (mounted) setState(() {});
  }

  Future<bool> _allowLargeDownload(
    AppSettings settings,
    _AudioCopy copy,
  ) async {
    final kind = await OfflineAudioManager.instance.currentNetworkKind();
    if (!mounted) return false;
    if (kind == AudioNetworkKind.offline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.noConnection)));
      return false;
    }
    if (settings.audioDownloadWifiOnly && kind != AudioNetworkKind.wifi) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.wifiRequired)));
      return false;
    }
    if (kind == AudioNetworkKind.mobile && settings.audioDownloadAskOnMobile) {
      return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(copy.mobileDataTitle),
              content: Text(copy.mobileDataBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(copy.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(copy.download),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  Future<bool> _ensureLinkedTranslation(
    ReaderAudioSourceConfig config,
    _AudioCopy copy,
  ) async {
    final info = translationById(config.sourceId);
    if (info == null ||
        info.bundled ||
        await TranslationRepository.instance.isInstalled(info.id)) {
      return true;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.translationRequiredTitle),
        content: Text('${info.name}\n\n${copy.translationRequiredBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.downloadTranslation),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return false;
    setState(() {
      _installingText = true;
      _textProgress = 0;
    });
    try {
      await TranslationRepository.instance.downloadTranslation(
        info,
        onProgress: (value) {
          if (mounted) setState(() => _textProgress = value);
        },
      );
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(copy.translationDownloadFailed)));
      }
      return false;
    } finally {
      if (mounted) setState(() => _installingText = false);
    }
  }

  Future<void> _startDownload(
    ReaderAudioSourceConfig config,
    _AudioCopy copy,
  ) async {
    final settings = AppSettingsScope.of(context);
    if (!await _ensureLinkedTranslation(config, copy)) return;
    if (!await _allowLargeDownload(settings, copy)) return;
    _refreshStats();
    unawaited(
      OfflineAudioManager.instance.downloadSurah(
        storageKey: config.cacheId,
        surah: widget.controller.surahNumber,
        verseCount: widget.controller.verseCount,
        urlForAyah: (ayah) =>
            config.urlForVerse(widget.controller.surahNumber, ayah),
      ),
    );
  }

  Future<void> _showNarratorPicker(_AudioCopy copy) async {
    if (widget.availableSources.length <= 1) return;
    final currentId = widget.controller.config?.id;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: .72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          copy.chooseNarrator,
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    itemCount: widget.availableSources.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final source = widget.availableSources[index];
                      final selectedSource = source.id == currentId;
                      final title = source.style == null
                          ? source.title
                          : '${source.title} · ${source.style}';
                      return ListTile(
                        selected: selectedSource,
                        selectedTileColor: scheme.primaryContainer.withValues(
                          alpha: .42,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selectedSource
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          foregroundColor: selectedSource
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          child: const Icon(Icons.record_voice_over_rounded),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(source.attribution),
                        trailing: selectedSource
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, source.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null || selected == currentId) return;
    await widget.onSourceSelected(selected);
  }

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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.availableSources.length > 1) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: OutlinedButton.icon(
                                onPressed: () => _showNarratorPicker(copy),
                                icon: const Icon(
                                  Icons.record_voice_over_rounded,
                                ),
                                label: Text(copy.switchNarrator),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                if (_installingText) ...[
                  LinearProgressIndicator(
                    value: _textProgress <= 0 ? null : _textProgress,
                  ),
                  const SizedBox(height: 8),
                  Text(copy.downloadingTranslation),
                  const SizedBox(height: 10),
                ],
                if (controller.config != null)
                  _AudioOfflineSection(
                    config: controller.config!,
                    statsFuture: _statsFor(controller.config!),
                    progress: OfflineAudioManager.instance.progressFor(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    estimateBytes: OfflineAudioManager.instance
                        .estimateSurahBytes(
                          verseCount: controller.verseCount,
                          bitrate: controller.config!.bitrate,
                        ),
                    copy: copy,
                    onDownload: () => _startDownload(controller.config!, copy),
                    onPause: () => OfflineAudioManager.instance.pauseDownload(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    onCancel: () => OfflineAudioManager.instance.cancelDownload(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    onDelete: () async {
                      await OfflineAudioManager.instance.deleteSurah(
                        controller.config!.cacheId,
                        controller.surahNumber,
                      );
                      _refreshStats();
                    },
                  ),
                if (controller.config != null &&
                    controller.config!.availableBitrates.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        copy.audioQuality,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      PopupMenuButton<int>(
                        initialValue: controller.config!.bitrate,
                        onSelected: (value) =>
                            unawaited(widget.onBitrateSelected(value)),
                        itemBuilder: (_) => [
                          for (final bitrate
                              in controller.config!.availableBitrates)
                            PopupMenuItem<int>(
                              value: bitrate,
                              child: Text(copy.qualityLabel(bitrate)),
                            ),
                        ],
                        child: Chip(
                          label: Text(
                            copy.qualityLabel(
                              controller.config!.bitrate ?? 128,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                      tooltip: copy.playbackSpeed,
                      initialValue: controller.rate,
                      onSelected: controller.setRate,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: .5, child: Text('0.5x')),
                        PopupMenuItem(value: .75, child: Text('0.75x')),
                        PopupMenuItem(value: 1.0, child: Text('1x')),
                        PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        PopupMenuItem(value: 2.0, child: Text('2x')),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          '${controller.rate.toStringAsFixed(controller.rate % 1 == 0 ? 0 : 2)}x',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<AudioAfterSurahBehavior>(
                      tooltip: copy.playbackBehavior,
                      initialValue: AppSettingsScope.of(
                        context,
                      ).audioAfterSurahBehavior,
                      onSelected: (value) async {
                        final settings = AppSettingsScope.of(context);
                        await settings.setAudioAfterSurahBehavior(value);
                        controller.setContinueAfterSurah(
                          value == AudioAfterSurahBehavior.continueNext,
                        );
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: AudioAfterSurahBehavior.continueNext,
                          child: Text(copy.continueNextSurah),
                        ),
                        PopupMenuItem(
                          value: AudioAfterSurahBehavior.stop,
                          child: Text(copy.stopAtSurahEnd),
                        ),
                      ],
                      icon: const Icon(Icons.queue_music_rounded, size: 29),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      tooltip: copy.timer,
                      onSelected: (value) {
                        if (value == 'end') {
                          controller.setSleepAtSurahEnd();
                        } else if (value == 'off') {
                          controller.setSleepTimer(null);
                        } else {
                          controller.setSleepTimer(
                            Duration(minutes: int.parse(value)),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        for (final minutes in const [10, 20, 30, 45])
                          PopupMenuItem(
                            value: '$minutes',
                            child: Text('$minutes ${copy.minutes}'),
                          ),
                        PopupMenuItem(
                          value: 'end',
                          child: Text(copy.endOfSurah),
                        ),
                        PopupMenuItem(value: 'off', child: Text(copy.off)),
                      ],
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 31,
                          color:
                              controller.sleepAtSurahEnd ||
                                  controller.sleepMinutes != null
                              ? scheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (controller.sleepAtSurahEnd ||
                    controller.sleepMinutes != null) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        controller.sleepAtSurahEnd
                            ? copy.endOfSurah
                            : '${controller.sleepMinutes} ${copy.minutes}',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () {
                    setState(
                      () => _quickControlsVisible = !_quickControlsVisible,
                    );
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
                    _quickControlsVisible ? copy.hideButtons : copy.showButtons,
                  ),
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

class _AudioOfflineSection extends StatelessWidget {
  const _AudioOfflineSection({
    required this.config,
    required this.statsFuture,
    required this.progress,
    required this.estimateBytes,
    required this.copy,
    required this.onDownload,
    required this.onPause,
    required this.onCancel,
    required this.onDelete,
  });

  final ReaderAudioSourceConfig config;
  final Future<AudioSurahStats> statsFuture;
  final AudioDownloadProgress? progress;
  final int estimateBytes;
  final _AudioCopy copy;
  final VoidCallback onDownload;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = progress;
    if (live != null && live.status == AudioDownloadStatus.downloading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${copy.downloading} ${live.downloadedAyahs}/${live.verseCount}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_rounded),
                  tooltip: copy.pauseDownload,
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: copy.cancel,
                ),
              ],
            ),
            LinearProgressIndicator(value: live.fraction.clamp(0, 1)),
          ],
        ),
      );
    }
    return FutureBuilder<AudioSurahStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final complete =
            live?.status == AudioDownloadStatus.completed ||
            (stats?.complete ?? false);
        final partial =
            live?.status == AudioDownloadStatus.paused ||
            live?.status == AudioDownloadStatus.failed ||
            (stats?.partial ?? false);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                complete
                    ? Icons.offline_pin_rounded
                    : Icons.download_for_offline_outlined,
                color: complete ? scheme.primary : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete
                          ? copy.offline
                          : partial
                          ? copy.resumeDownload
                          : copy.downloadSurah,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      complete
                          ? _formatBytes(stats?.bytes ?? live?.bytes ?? 0)
                          : partial
                          ? '${stats?.downloadedAyahs ?? live?.downloadedAyahs ?? 0}/${stats?.verseCount ?? live?.verseCount ?? 0} · ${copy.resumeHint}'
                          : '${copy.estimated} ${_formatBytes(estimateBytes)}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (complete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: copy.delete,
                )
              else
                FilledButton.tonal(
                  onPressed: onDownload,
                  child: Text(partial ? copy.resume : copy.download),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
  String get chooseVerse =>
      _pick('Ayet seç', 'Choose verse', 'اختر الآية', 'Ayə seç', 'Выбрать аят');
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
  String get downloadSurah => _pick(
    'Bu sureyi indir',
    'Download this surah',
    'تنزيل هذه السورة',
    'Bu surəni endir',
    'Скачать эту суру',
  );
  String get download =>
      _pick('İndir', 'Download', 'تنزيل', 'Endir', 'Скачать');
  String get downloading => _pick(
    'İndiriliyor',
    'Downloading',
    'جارٍ التنزيل',
    'Endirilir',
    'Загрузка',
  );
  String get offline => _pick(
    'Offline hazır',
    'Available offline',
    'متاح دون اتصال',
    'Oflayn hazırdır',
    'Доступно офлайн',
  );
  String get resume =>
      _pick('Devam et', 'Resume', 'متابعة', 'Davam et', 'Продолжить');
  String get resumeDownload => _pick(
    'İndirmeye devam et',
    'Resume download',
    'متابعة التنزيل',
    'Endirməyə davam et',
    'Продолжить загрузку',
  );
  String get resumeHint => _pick(
    'kaldığı yerden devam eder',
    'continues where it stopped',
    'يتابع من حيث توقف',
    'qaldığı yerdən davam edir',
    'продолжит с места остановки',
  );
  String get pauseDownload => _pick(
    'İndirmeyi duraklat',
    'Pause download',
    'إيقاف التنزيل مؤقتًا',
    'Endirməni dayandır',
    'Приостановить загрузку',
  );
  String get delete => _pick('Sil', 'Delete', 'حذف', 'Sil', 'Удалить');
  String get cancel => _pick('İptal', 'Cancel', 'إلغاء', 'Ləğv et', 'Отмена');
  String get estimated =>
      _pick('Yaklaşık', 'About', 'تقريبًا', 'Təxminən', 'Примерно');
  String get audioQuality => _pick(
    'Ses kalitesi',
    'Audio quality',
    'جودة الصوت',
    'Səs keyfiyyəti',
    'Качество аудио',
  );
  String qualityLabel(int bitrate) => bitrate <= 64
      ? _pick(
          'Veri tasarrufu · $bitrate kbps',
          'Data saver · $bitrate kbps',
          'توفير البيانات · $bitrate kbps',
          'Məlumat qənaəti · $bitrate kbps',
          'Экономия данных · $bitrate kbps',
        )
      : _pick(
          'Standart · $bitrate kbps',
          'Standard · $bitrate kbps',
          'قياسي · $bitrate kbps',
          'Standart · $bitrate kbps',
          'Стандарт · $bitrate kbps',
        );
  String get switchNarrator => _pick(
    'Okuyucuyu değiştir',
    'Switch narrator',
    'تغيير القارئ',
    'Oxucunu dəyiş',
    'Сменить чтеца',
  );
  String get chooseNarrator => _pick(
    'Okuyucu seç',
    'Choose narrator',
    'اختر القارئ',
    'Oxucu seç',
    'Выбрать чтеца',
  );
  String get playbackSpeed => _pick(
    'Oynatma hızı',
    'Playback speed',
    'سرعة التشغيل',
    'Oxutma sürəti',
    'Скорость воспроизведения',
  );
  String get playbackBehavior => _pick(
    'Sure sonu davranışı',
    'End-of-surah behavior',
    'سلوك نهاية السورة',
    'Surə sonu davranışı',
    'Поведение в конце суры',
  );
  String get timer =>
      _pick('Zamanlayıcı', 'Timer', 'المؤقت', 'Taymer', 'Таймер');
  String get minutes => _pick('dk', 'min', 'د', 'dəq', 'мин');
  String get endOfSurah => _pick(
    'Sure bitince',
    'End of surah',
    'عند نهاية السورة',
    'Surə bitəndə',
    'В конце суры',
  );
  String get off => _pick('Kapalı', 'Off', 'إيقاف', 'Söndürülüb', 'Выкл.');
  String get continueNext =>
      _pick('Devam', 'Continue', 'متابعة', 'Davam', 'Продолжить');
  String get stop => _pick('Dur', 'Stop', 'توقف', 'Dayan', 'Стоп');
  String get continueNextSurah => _pick(
    'Sonraki sureye devam et',
    'Continue to next surah',
    'المتابعة إلى السورة التالية',
    'Növbəti surəyə davam et',
    'Продолжить следующую суру',
  );
  String get stopAtSurahEnd => _pick(
    'Sure bitince dur',
    'Stop at end of surah',
    'توقف عند نهاية السورة',
    'Surə bitəndə dayan',
    'Остановиться в конце суры',
  );
  String get noConnection => _pick(
    'İnternet bağlantısı yok.',
    'No internet connection.',
    'لا يوجد اتصال بالإنترنت.',
    'İnternet bağlantısı yoxdur.',
    'Нет подключения к интернету.',
  );
  String get wifiRequired => _pick(
    'Büyük indirmeler yalnızca Wi‑Fi ile açık. İndirilenler ayarından değiştirebilirsin.',
    'Large downloads are Wi‑Fi only. Change it in Downloads settings.',
    'التنزيلات الكبيرة عبر Wi‑Fi فقط.',
    'Böyük endirmələr yalnız Wi‑Fi üçündür.',
    'Большие загрузки разрешены только по Wi‑Fi.',
  );
  String get mobileDataTitle => _pick(
    'Mobil veri kullanılsın mı?',
    'Use mobile data?',
    'استخدام بيانات الهاتف؟',
    'Mobil data istifadə edilsin?',
    'Использовать мобильные данные?',
  );
  String get mobileDataBody => _pick(
    'Ses dosyaları büyük olabilir. Bu sureyi mobil veri ile indirmek istiyor musun?',
    'Audio files can be large. Download this surah over mobile data?',
    'قد تكون ملفات الصوت كبيرة. هل تريد التنزيل عبر بيانات الهاتف؟',
    'Səs faylları böyük ola bilər. Mobil data ilə endirilsin?',
    'Аудиофайлы могут быть большими. Скачать через мобильную сеть?',
  );
  String get translationRequiredTitle => _pick(
    'Meal metni gerekli',
    'Translation text required',
    'نص الترجمة مطلوب',
    'Tərcümə mətni lazımdır',
    'Нужен текст перевода',
  );
  String get translationRequiredBody => _pick(
    'Bu ses yalnız kendi meal metniyle kullanılabilir. Önce eşleşen meal indirilecek.',
    'This audio can only be used with its matching translation. The matching text will be downloaded first.',
    'لا يمكن استخدام هذا الصوت إلا مع ترجمته المطابقة.',
    'Bu səs yalnız uyğun tərcümə ilə istifadə olunur.',
    'Это аудио используется только с соответствующим переводом.',
  );
  String get downloadTranslation => _pick(
    'Meali indir',
    'Download translation',
    'تنزيل الترجمة',
    'Tərcüməni endir',
    'Скачать перевод',
  );
  String get downloadingTranslation => _pick(
    'Eşleşen meal indiriliyor…',
    'Downloading matching translation…',
    'جارٍ تنزيل الترجمة المطابقة…',
    'Uyğun tərcümə endirilir…',
    'Загружается соответствующий перевод…',
  );
  String get translationDownloadFailed => _pick(
    'Meal indirilemedi. Bağlantıyı kontrol edip tekrar dene.',
    'Translation could not be downloaded. Check the connection and try again.',
    'تعذر تنزيل الترجمة.',
    'Tərcümə endirilə bilmədi.',
    'Не удалось скачать перевод.',
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
