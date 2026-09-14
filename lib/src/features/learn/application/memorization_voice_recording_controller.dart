import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'memorization_voice_recording_service.dart';

enum MemorizationVoiceRecordingPhase { loading, idle, recording, recorded }

/// Page-scoped state boundary between the hifz study UI and the platform
/// recording service.
///
/// This controller intentionally exposes only recording lifecycle state. It
/// does not perform speech recognition, recitation scoring or any remote work.
class MemorizationVoiceRecordingController extends ChangeNotifier {
  MemorizationVoiceRecordingController({
    required this.page,
    MemorizationVoiceRecordingService? service,
  }) : _service = service ?? MemorizationVoiceRecordingService();

  final int page;
  final MemorizationVoiceRecordingService _service;

  MemorizationVoiceRecordingPhase _phase =
      MemorizationVoiceRecordingPhase.loading;
  StreamSubscription<PlayerState>? _playbackSubscription;
  bool _permissionDenied = false;
  bool _isPlaying = false;
  bool _recordingTransitionInFlight = false;
  bool _playbackTransitionInFlight = false;
  bool _disposed = false;

  MemorizationVoiceRecordingPhase get phase => _phase;
  bool get permissionDenied => _permissionDenied;
  bool get isRecording => phase == MemorizationVoiceRecordingPhase.recording;
  bool get hasRecording => phase == MemorizationVoiceRecordingPhase.recorded;
  bool get isPlaying => _isPlaying;

  Future<void> initialize() async {
    await _playbackSubscription?.cancel();
    _isPlaying = _service.playbackState == PlayerState.playing;
    _playbackSubscription = _service.playbackStateChanges.listen(
      (state) => _setPlaying(state == PlayerState.playing),
    );

    final existing = await _service.existingRecordingPath(page);
    _setState(
      existing == null
          ? MemorizationVoiceRecordingPhase.idle
          : MemorizationVoiceRecordingPhase.recorded,
      permissionDenied: false,
    );
  }

  Future<bool> start() async {
    if (phase == MemorizationVoiceRecordingPhase.loading ||
        isRecording ||
        _recordingTransitionInFlight ||
        _playbackTransitionInFlight) {
      return false;
    }

    _recordingTransitionInFlight = true;
    try {
      final result = await _service.start(page);
      if (result == MemorizationRecordingStartResult.permissionDenied) {
        _setState(phase, permissionDenied: true);
        return false;
      }

      _setPlaying(false);
      _setState(
        MemorizationVoiceRecordingPhase.recording,
        permissionDenied: false,
      );
      return true;
    } finally {
      _recordingTransitionInFlight = false;
    }
  }

  Future<bool> stop() async {
    if (!isRecording || _recordingTransitionInFlight) return false;

    _recordingTransitionInFlight = true;
    try {
      final saved = await _service.stop();
      final existing =
          saved ? null : await _service.existingRecordingPath(page);
      _setState(
        saved || existing != null
            ? MemorizationVoiceRecordingPhase.recorded
            : MemorizationVoiceRecordingPhase.idle,
        permissionDenied: false,
      );
      return saved;
    } finally {
      _recordingTransitionInFlight = false;
    }
  }

  /// Starts a local recording when idle/recorded and saves it when already
  /// recording. Calls made while initialization or another recording
  /// transition is still pending are ignored so rapid taps cannot create
  /// overlapping platform recorder operations.
  Future<bool> toggleRecording() async {
    if (phase == MemorizationVoiceRecordingPhase.loading ||
        _recordingTransitionInFlight) {
      return false;
    }
    return isRecording ? stop() : start();
  }

  Future<void> cancel() async {
    if (phase == MemorizationVoiceRecordingPhase.loading ||
        _recordingTransitionInFlight) {
      return;
    }
    await _service.cancel();
    final existing = await _service.existingRecordingPath(page);
    _setState(
      existing == null
          ? MemorizationVoiceRecordingPhase.idle
          : MemorizationVoiceRecordingPhase.recorded,
      permissionDenied: false,
    );
  }

  Future<bool> togglePlayback() async {
    if (isRecording ||
        _recordingTransitionInFlight ||
        _playbackTransitionInFlight) {
      return false;
    }

    _playbackTransitionInFlight = true;
    try {
      if (isPlaying) {
        await _service.pausePlayback();
        _setPlaying(false);
        return true;
      }

      if (!hasRecording) return false;
      final started = await _service.play(page);
      if (started) _setPlaying(true);
      return started;
    } finally {
      _playbackTransitionInFlight = false;
    }
  }

  Future<bool> delete() async {
    if (phase == MemorizationVoiceRecordingPhase.loading ||
        _recordingTransitionInFlight ||
        _playbackTransitionInFlight) {
      return false;
    }
    if (isRecording) {
      await _service.cancel();
    }
    final deleted = await _service.delete(page);
    _setPlaying(false);
    _setState(
      MemorizationVoiceRecordingPhase.idle,
      permissionDenied: false,
    );
    return deleted;
  }

  void _setState(
    MemorizationVoiceRecordingPhase next, {
    required bool permissionDenied,
  }) {
    if (_disposed) return;
    final changed = _phase != next || _permissionDenied != permissionDenied;
    _phase = next;
    _permissionDenied = permissionDenied;
    if (changed) notifyListeners();
  }

  void _setPlaying(bool next) {
    if (_disposed || _isPlaying == next) return;
    _isPlaying = next;
    notifyListeners();
  }

  Future<void> _disposeResources() async {
    await _playbackSubscription?.cancel();
    await _service.dispose();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeResources());
    super.dispose();
  }
}
