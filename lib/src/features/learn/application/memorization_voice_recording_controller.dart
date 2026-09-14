import 'dart:async';

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
  bool _permissionDenied = false;
  bool _disposed = false;

  MemorizationVoiceRecordingPhase get phase => _phase;
  bool get permissionDenied => _permissionDenied;
  bool get isRecording => phase == MemorizationVoiceRecordingPhase.recording;
  bool get hasRecording => phase == MemorizationVoiceRecordingPhase.recorded;

  Future<void> initialize() async {
    final existing = await _service.existingRecordingPath(page);
    _setState(
      existing == null
          ? MemorizationVoiceRecordingPhase.idle
          : MemorizationVoiceRecordingPhase.recorded,
      permissionDenied: false,
    );
  }

  Future<bool> start() async {
    final result = await _service.start(page);
    if (result == MemorizationRecordingStartResult.permissionDenied) {
      _setState(phase, permissionDenied: true);
      return false;
    }

    _setState(
      MemorizationVoiceRecordingPhase.recording,
      permissionDenied: false,
    );
    return true;
  }

  Future<bool> stop() async {
    if (!isRecording) return false;
    final saved = await _service.stop();
    _setState(
      saved
          ? MemorizationVoiceRecordingPhase.recorded
          : MemorizationVoiceRecordingPhase.idle,
      permissionDenied: false,
    );
    return saved;
  }

  Future<void> cancel() async {
    await _service.cancel();
    final existing = await _service.existingRecordingPath(page);
    _setState(
      existing == null
          ? MemorizationVoiceRecordingPhase.idle
          : MemorizationVoiceRecordingPhase.recorded,
      permissionDenied: false,
    );
  }

  Future<bool> delete() async {
    if (isRecording) {
      await _service.cancel();
    }
    final deleted = await _service.delete(page);
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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_service.dispose());
    super.dispose();
  }
}
