import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_controller.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_service.dart';

void main() {
  test('serializes rapid recording start requests', () async {
    final startGate = Completer<void>();
    final service = _DelayedRecordingService(startGate: startGate);
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();

    final firstStart = controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.start(), isFalse);
    expect(await controller.toggleRecording(), isFalse);
    expect(service.startCalls, 1);

    startGate.complete();
    expect(await firstStart, isTrue);
    expect(controller.isRecording, isTrue);
    controller.dispose();
  });

  test('blocks playback while recording start is pending', () async {
    final startGate = Completer<void>();
    final service = _DelayedRecordingService(startGate: startGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingStart = controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.togglePlayback(), isFalse);
    expect(service.playCalls, 0);

    startGate.complete();
    expect(await pendingStart, isTrue);
    expect(controller.isRecording, isTrue);
    controller.dispose();
  });

  test('serializes rapid playback start requests', () async {
    final playGate = Completer<void>();
    final service = _DelayedRecordingService(playGate: playGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final firstPlay = controller.togglePlayback();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.togglePlayback(), isFalse);
    expect(service.playCalls, 1);

    playGate.complete();
    expect(await firstPlay, isTrue);
    expect(controller.isPlaying, isTrue);
    controller.dispose();
  });

  test('blocks recording start while playback start is pending', () async {
    final playGate = Completer<void>();
    final service = _DelayedRecordingService(playGate: playGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingPlay = controller.togglePlayback();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.start(), isFalse);
    expect(await controller.toggleRecording(), isFalse);
    expect(service.startCalls, 0);

    playGate.complete();
    expect(await pendingPlay, isTrue);
    expect(controller.isPlaying, isTrue);
    controller.dispose();
  });

  test('blocks delete while playback start is pending', () async {
    final playGate = Completer<void>();
    final service = _DelayedRecordingService(playGate: playGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingPlay = controller.togglePlayback();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.delete(), isFalse);
    expect(service.deleteCalls, 0);
    expect(service.existingPath, '/tmp/page_042.m4a');

    playGate.complete();
    expect(await pendingPlay, isTrue);
    expect(controller.isPlaying, isTrue);
    controller.dispose();
  });

  test('blocks cancel while playback start is pending', () async {
    final playGate = Completer<void>();
    final service = _DelayedRecordingService(playGate: playGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingPlay = controller.togglePlayback();
    await Future<void>.delayed(Duration.zero);

    await controller.cancel();
    expect(service.cancelCalls, 0);
    expect(service.existingPath, '/tmp/page_042.m4a');

    playGate.complete();
    expect(await pendingPlay, isTrue);
    expect(controller.isPlaying, isTrue);
    controller.dispose();
  });

  test('blocks delete while recording start is pending', () async {
    final startGate = Completer<void>();
    final service = _DelayedRecordingService(startGate: startGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingStart = controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.delete(), isFalse);
    expect(service.deleteCalls, 0);
    expect(service.existingPath, '/tmp/page_042.m4a');

    startGate.complete();
    expect(await pendingStart, isTrue);
    expect(controller.isRecording, isTrue);
    controller.dispose();
  });

  test('blocks cancel while recording start is pending', () async {
    final startGate = Completer<void>();
    final service = _DelayedRecordingService(startGate: startGate)
      ..existingPath = '/tmp/page_042.m4a';
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(controller.hasRecording, isTrue);

    final pendingStart = controller.start();
    await Future<void>.delayed(Duration.zero);

    await controller.cancel();
    expect(service.cancelCalls, 0);
    expect(service.existingPath, '/tmp/page_042.m4a');

    startGate.complete();
    expect(await pendingStart, isTrue);
    expect(controller.isRecording, isTrue);
    controller.dispose();
  });

  test('serializes rapid recording stop requests', () async {
    final stopGate = Completer<void>();
    final service = _DelayedRecordingService(stopGate: stopGate);
    final controller = MemorizationVoiceRecordingController(
      page: 42,
      service: service,
    );

    await controller.initialize();
    expect(await controller.start(), isTrue);

    final firstStop = controller.stop();
    await Future<void>.delayed(Duration.zero);

    expect(await controller.stop(), isFalse);
    expect(await controller.toggleRecording(), isFalse);
    expect(service.stopCalls, 1);

    service.existingPath = '/tmp/page_042.m4a';
    stopGate.complete();
    expect(await firstStop, isTrue);
    expect(controller.hasRecording, isTrue);
    controller.dispose();
  });
}

class _DelayedRecordingService implements MemorizationVoiceRecordingService {
  _DelayedRecordingService({this.startGate, this.stopGate, this.playGate});

  final Completer<void>? startGate;
  final Completer<void>? stopGate;
  final Completer<void>? playGate;
  final StreamController<PlayerState> _playbackStates =
      StreamController<PlayerState>.broadcast();

  String? existingPath;
  bool recording = false;
  int startCalls = 0;
  int stopCalls = 0;
  int playCalls = 0;
  int deleteCalls = 0;
  int cancelCalls = 0;
  PlayerState _playbackState = PlayerState.stopped;

  @override
  bool get hasActiveRecording => recording;

  @override
  PlayerState get playbackState => _playbackState;

  @override
  Stream<PlayerState> get playbackStateChanges => _playbackStates.stream;

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    recording = false;
  }

  @override
  Future<bool> delete(int page) async {
    deleteCalls += 1;
    final deleted = existingPath != null;
    existingPath = null;
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
    _playbackState = PlayerState.paused;
    _playbackStates.add(_playbackState);
  }

  @override
  Future<bool> play(int page) async {
    playCalls += 1;
    if (playGate != null) await playGate!.future;
    return existingPath != null;
  }

  @override
  Future<String> recordingPathForPage(int page) async =>
      '/tmp/page_${page.toString().padLeft(3, '0')}.m4a';

  @override
  Future<MemorizationRecordingStartResult> start(int page) async {
    startCalls += 1;
    if (startGate != null) await startGate!.future;
    recording = true;
    return MemorizationRecordingStartResult.started;
  }

  @override
  Future<bool> stop() async {
    stopCalls += 1;
    if (stopGate != null) await stopGate!.future;
    if (!recording) return false;
    recording = false;
    return true;
  }
}
