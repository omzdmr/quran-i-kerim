import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/quran_audio_track.dart';
import 'audio_sleep_timer.dart';

/// Background-capable Quran player used by system media controls.
///
/// It owns the playback queue and keeps AudioService's queue/media metadata in
/// sync with just_audio so lock-screen and notification controls always point
/// at the active ayah.
class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  QuranAudioHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _sleepTimer = AudioSleepTimer(
      onExpired: () {
        // Expiry must stop audible playback even when the app is backgrounded.
        // Keep the loaded queue/current ayah so the user can resume later.
        unawaited(pause());
      },
    );
    _subscriptions.add(
      _player.playbackEventStream.listen((_) => _broadcastPlaybackState()),
    );
    _subscriptions.add(
      _player.playingStream.listen((_) => _broadcastPlaybackState()),
    );
    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        final items = queue.value;
        if (index == null || index < 0 || index >= items.length) return;
        mediaItem.add(items[index]);
        _broadcastPlaybackState();
      }),
    );
  }

  final AudioPlayer _player;
  late final AudioSleepTimer _sleepTimer;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  bool get isSleepTimerActive => _sleepTimer.isActive;

  Duration get sleepTimerRemaining => _sleepTimer.remaining;

  DateTime? get sleepTimerDeadline => _sleepTimer.deadline;

  void startSleepTimerForMinutes(int minutes) {
    _sleepTimer.startForMinutes(minutes);
  }

  void startSleepTimerForHours(int hours) {
    _sleepTimer.startForHours(hours);
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer.start(duration);
  }

  void cancelSleepTimer() {
    _sleepTimer.cancel();
  }

  Future<void> loadTracks(
    List<QuranAudioTrack> tracks, {
    int initialIndex = 0,
    bool autoplay = false,
  }) async {
    if (tracks.isEmpty) {
      await stop();
      queue.add(const <MediaItem>[]);
      mediaItem.add(null);
      return;
    }

    final safeIndex = initialIndex.clamp(0, tracks.length - 1).toInt();
    final items = tracks.map((track) => track.toMediaItem()).toList(growable: false);
    final sources = tracks
        .map((track) => AudioSource.uri(track.uri, tag: track.toMediaItem()))
        .toList(growable: false);

    queue.add(items);
    mediaItem.add(items[safeIndex]);
    await _player.setAudioSources(sources, initialIndex: safeIndex);
    if (autoplay) {
      await play();
    } else {
      _broadcastPlaybackState();
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    final items = queue.value;
    if (index < 0 || index >= items.length) return;
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(items[index]);
  }

  @override
  Future<void> skipToNext() async {
    final index = _player.currentIndex ?? 0;
    await skipToQueueItem(index + 1);
  }

  @override
  Future<void> skipToPrevious() async {
    final index = _player.currentIndex ?? 0;
    await skipToQueueItem(index - 1);
  }

  @override
  Future<void> stop() async {
    _sleepTimer.cancel();
    await _player.stop();
    await super.stop();
  }

  Future<void> disposePlayer() async {
    _sleepTimer.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
  }

  void _broadcastPlaybackState() {
    final event = _player.playbackEvent;
    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState: switch (event.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
