import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_controller.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_service.dart';

void main() {
  group('MemorizationVoiceRecordingController', () {
    test('loads an existing local page recording', () async {
      final service = _FakeRecordingService(existingPath: '/tmp/page_042.m4a');
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();

      expect(controller.phase, MemorizationVoiceRecordingPhase.recorded);
      expect(controller.hasRecording, isTrue);
      controller.dispose();
    });

    test('moves from idle to recording to recorded', () async {
      final service = _FakeRecordingService();
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();
      expect(controller.phase, MemorizationVoiceRecordingPhase.idle);

      expect(await controller.start(), isTrue);
      expect(controller.phase, MemorizationVoiceRecordingPhase.recording);

      service.existingPath = '/tmp/page_042.m4a';
      expect(await controller.stop(), isTrue);
      expect(controller.phase, MemorizationVoiceRecordingPhase.recorded);
      controller.dispose();
    });

    test('toggle recording is ignored while initialization is pending', () async {
      final service = _FakeRecordingService();
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      expect(await controller.toggleRecording(), isFalse);
      expect(controller.phase, MemorizationVoiceRecordingPhase.loading);
      expect(service.startCalls, 0);
      controller.dispose();
    });

    test('toggle recording starts then saves the page recording', () async {
      final service = _FakeRecordingService();
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();

      expect(await controller.toggleRecording(), isTrue);
      expect(controller.phase, MemorizationVoiceRecordingPhase.recording);
      expect(service.startCalls, 1);

      service.existingPath = '/tmp/page_042.m4a';
      expect(await controller.toggleRecording(), isTrue);
      expect(controller.phase, MemorizationVoiceRecordingPhase.recorded);
      expect(service.stopCalls, 1);
      controller.dispose();
    });

    test('repeated start does not restart an active recording', () async {
      final service = _FakeRecordingService();
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();
      expect(await controller.start(), isTrue);
      expect(await controller.start(), isFalse);

      expect(controller.phase, MemorizationVoiceRecordingPhase.recording);
      expect(service.startCalls, 1);
      controller.dispose();
    });

    test('keeps idle state and exposes permission denial', () async {
      final service = _FakeRecordingService(permissionDenied: true);
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();

      expect(await controller.start(), isFalse);
      expect(controller.phase, MemorizationVoiceRecordingPhase.idle);
      expect(controller.permissionDenied, isTrue);
      controller.dispose();
    });

    test('cancel preserves a previously saved recording', () async {
      final service = _FakeRecordingService(existingPath: '/tmp/page_042.m4a');
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();
      await controller.start();
      await controller.cancel();

      expect(controller.phase, MemorizationVoiceRecordingPhase.recorded);
      controller.dispose();
    });

    test('plays and pauses the saved page recording', () async {
      final service = _FakeRecordingService(existingPath: '/tmp/page_042.m4a');
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();

      expect(await controller.togglePlayback(), isTrue);
      expect(controller.isPlaying, isTrue);

      expect(await controller.togglePlayback(), isTrue);
      expect(controller.isPlaying, isFalse);
      controller.dispose();
    });

    test('tracks playback completion from the service', () async {
      final service = _FakeRecordingService(existingPath: '/tmp/page_042.m4a');
      final controller = MemorizationVoiceRecordingController(
        page: 42,
        service: service,
      );

      await controller.initialize();
      await controller.togglePlayback();
      expect(controller.isPlaying, isTrue);

      service.emitPlaybackState(PlayerState.completed);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPlaying, isFalse);
      controller.dispose();
    });
  });
}

class _FakeRecordingService implements MemorizationVoiceRecordingService {
  _FakeRecordingService({this.existingPath, this.permissionDenied = false});

  final StreamController<PlayerState> _playbackStates =
      StreamController<PlayerState>.broadcast();
  String? existingPath;
  bool permissionDenied;
  bool recording = false;
  int startCalls = 0;
  int stopCalls = 0;
  PlayerState _playbackState = PlayerState.stopped;

  @override
  bool get hasActiveRecording => recording;

  @override
  PlayerState get playbackState => _playbackState;

  @override
  Stream<PlayerState> get playbackStateChanges => _playbackStates.stream;

  void emitPlaybackState(PlayerState state) {
    _playbackState = state;
    _playbackStates.add(state);
  }

  @override
  Future<void> cancel() async {
    recording = false;
  }

  @override
  Future<bool> delete(int page) async {
    final deleted = existingPath != null;
    existingPath = null;
    emitPlaybackState(PlayerState.stopped);
    return deleted;
  }

  @override
  Future<void> dispose() async {
    await _playbackStates.close();
  }

  @override
  Future<String?> existingRecordingPath(int page) async => existingPath;

  @override
  Future<void> pausePlayback() async {
    emitPlaybackState(PlayerState.paused);
  }

  @override
  Future<bool> play(int page) async {
    if (existingPath == null || recording) return false;
    emitPlaybackState(PlayerState.playing);
    return true;
  }

  @override
  Future<String> recordingPathForPage(int page) async =>
      '/tmp/page_${page.toString().padLeft(3, '0')}.m4a';

  @override
  Future<MemorizationRecordingStartResult> start(int page) async {
    startCalls += 1;
    if (permissionDenied) {
      return MemorizationRecordingStartResult.permissionDenied;
    }
    emitPlaybackState(PlayerState.stopped);
    recording = true;
    return MemorizationRecordingStartResult.started;
  }

  @override
  Future<bool> stop() async {
    stopCalls += 1;
    if (!recording) return false;
    recording = false;
    return true;
  }
}
