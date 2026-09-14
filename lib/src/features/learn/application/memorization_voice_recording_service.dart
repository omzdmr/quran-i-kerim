import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum MemorizationRecordingStartResult { started, permissionDenied }

String memorizationVoiceRecordingFileName(int page) {
  if (page < 1 || page > 604) {
    throw ArgumentError.value(page, 'page', 'must be between 1 and 604');
  }
  return 'page_${page.toString().padLeft(3, '0')}.m4a';
}

String memorizationVoiceRecordingPendingFileName(int page) =>
    '.pending_${memorizationVoiceRecordingFileName(page)}';

/// Local-only recorder used by the hifz study flow.
///
/// It deliberately does not perform speech recognition or recitation scoring.
/// The user records, listens back, compares with the Mushaf/human reciter and
/// then records their own memorization assessment elsewhere in the hifz flow.
class MemorizationVoiceRecordingService {
  MemorizationVoiceRecordingService({
    AudioRecorder? recorder,
    AudioPlayer? player,
  })  : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  static const _directoryName = 'memorization_recordings';
  static const _recordConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 96000,
    sampleRate: 44100,
    numChannels: 1,
  );

  final AudioRecorder _recorder;
  final AudioPlayer _player;

  int? _activePage;
  String? _pendingPath;

  Stream<PlayerState> get playbackStateChanges => _player.onPlayerStateChanged;
  PlayerState get playbackState => _player.state;
  bool get hasActiveRecording => _activePage != null;

  Future<Directory> _recordingDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$_directoryName',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> recordingPathForPage(int page) async {
    final fileName = memorizationVoiceRecordingFileName(page);
    final directory = await _recordingDirectory();
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }

  Future<String?> existingRecordingPath(int page) async {
    final path = await recordingPathForPage(page);
    return await File(path).exists() ? path : null;
  }

  Future<MemorizationRecordingStartResult> start(int page) async {
    memorizationVoiceRecordingFileName(page);

    if (!await _recorder.hasPermission()) {
      return MemorizationRecordingStartResult.permissionDenied;
    }

    if (_activePage != null || await _recorder.isRecording()) {
      await cancel();
    }
    await _player.stop();

    final directory = await _recordingDirectory();
    final pendingPath =
        '${directory.path}${Platform.pathSeparator}${memorizationVoiceRecordingPendingFileName(page)}';
    final pendingFile = File(pendingPath);
    if (await pendingFile.exists()) {
      await pendingFile.delete();
    }

    try {
      await _recorder.start(_recordConfig, path: pendingPath);
      _activePage = page;
      _pendingPath = pendingPath;
      return MemorizationRecordingStartResult.started;
    } catch (_) {
      _activePage = null;
      _pendingPath = null;
      rethrow;
    }
  }

  Future<bool> stop() async {
    final page = _activePage;
    final pendingPath = _pendingPath;
    if (page == null || pendingPath == null) return false;

    String? stoppedPath;
    try {
      stoppedPath = await _recorder.stop();
    } finally {
      _activePage = null;
      _pendingPath = null;
    }

    final source = File(_fileSystemPath(stoppedPath ?? pendingPath));
    if (!await source.exists()) return false;

    final target = File(await recordingPathForPage(page));
    if (source.path == target.path) return true;
    if (await target.exists()) {
      await target.delete();
    }

    try {
      await source.rename(target.path);
    } on FileSystemException {
      await source.copy(target.path);
      await source.delete();
    }
    return true;
  }

  Future<void> cancel() async {
    final pendingPath = _pendingPath;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.cancel();
      }
    } finally {
      _activePage = null;
      _pendingPath = null;
      if (pendingPath != null) {
        final pendingFile = File(pendingPath);
        if (await pendingFile.exists()) {
          await pendingFile.delete();
        }
      }
    }
  }

  Future<bool> play(int page) async {
    final path = await existingRecordingPath(page);
    if (path == null) return false;
    if (_activePage != null) return false;

    await _player.play(DeviceFileSource(path));
    return true;
  }

  Future<void> pausePlayback() => _player.pause();

  Future<bool> delete(int page) async {
    await _player.stop();
    final path = await recordingPathForPage(page);
    final file = File(path);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  Future<void> dispose() async {
    await cancel();
    await _player.dispose();
    await _recorder.dispose();
  }
}

String _fileSystemPath(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.scheme == 'file') {
    return uri.toFilePath();
  }
  return value;
}
