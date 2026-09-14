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
  });
}

class _FakeRecordingService implements MemorizationVoiceRecordingService {
  _FakeRecordingService({this.existingPath, this.permissionDenied = false});

  String? existingPath;
  bool permissionDenied;
  bool recording = false;

  @override
  bool get hasActiveRecording => recording;

  @override
  PlayerState get playbackState => PlayerState.stopped;

  @override
  Stream<PlayerState> get playbackStateChanges => const Stream.empty();

  @override
  Future<void> cancel() async {
    recording = false;
  }

  @override
  Future<bool> delete(int page) async {
    final deleted = existingPath != null;
    existingPath = null;
    return deleted;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> existingRecordingPath(int page) async => existingPath;

  @override
  Future<void> pausePlayback() async {}

  @override
  Future<bool> play(int page) async => existingPath != null && !recording;

  @override
  Future<String> recordingPathForPage(int page) async =>
      '/tmp/page_${page.toString().padLeft(3, '0')}.m4a';

  @override
  Future<MemorizationRecordingStartResult> start(int page) async {
    if (permissionDenied) {
      return MemorizationRecordingStartResult.permissionDenied;
    }
    recording = true;
    return MemorizationRecordingStartResult.started;
  }

  @override
  Future<bool> stop() async {
    if (!recording) return false;
    recording = false;
    return true;
  }
}
