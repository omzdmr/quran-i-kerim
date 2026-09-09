import 'package:audio_service/audio_service.dart';

/// Bridges the reader's existing audio engine to Android/iOS system media
/// controls. The actual audio files are still owned by ReaderAudioController,
/// preserving the local-first cache/offline architecture.
class ReaderMediaSession extends BaseAudioHandler {
  ReaderMediaSession._();

  static ReaderMediaSession? instance;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function()? _onPrevious;
  Future<void> Function()? _onNext;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onStop;

  static Future<void> initialize() async {
    if (instance != null) return;
    await AudioService.init(
      builder: () {
        final handler = ReaderMediaSession._();
        instance = handler;
        return handler;
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.omzdmr.quran_i_kerim.audio',
        androidNotificationChannelName: 'Kur’an sesi',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
      ),
    );
  }

  void attach({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onPrevious,
    required Future<void> Function() onNext,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onStop,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onPrevious = onPrevious;
    _onNext = onNext;
    _onSeek = onSeek;
    _onStop = onStop;
  }

  void detach() {
    _onPlay = null;
    _onPause = null;
    _onPrevious = null;
    _onNext = null;
    _onSeek = null;
    _onStop = null;
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        controls: const <MediaControl>[],
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  void publish({
    required int surah,
    required int ayah,
    required int verseCount,
    required String sourceTitle,
    required Duration position,
    required Duration duration,
    required bool playing,
    required bool loading,
    required double speed,
  }) {
    mediaItem.add(
      MediaItem(
        id: 'quran:$surah:$ayah',
        album: sourceTitle,
        title: 'Kur’an $surah:$ayah',
        artist: '$sourceTitle · Ayet $ayah/$verseCount',
        duration: duration > Duration.zero ? duration : null,
      ),
    );
    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const <MediaAction>{MediaAction.seek},
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState:
            loading ? AudioProcessingState.loading : AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: speed,
      ),
    );
  }

  @override
  Future<void> play() async => _onPlay?.call();

  @override
  Future<void> pause() async => _onPause?.call();

  @override
  Future<void> skipToPrevious() async => _onPrevious?.call();

  @override
  Future<void> skipToNext() async => _onNext?.call();

  @override
  Future<void> seek(Duration position) async => _onSeek?.call(position);

  @override
  Future<void> stop() async {
    await _onStop?.call();
    await super.stop();
  }
}
