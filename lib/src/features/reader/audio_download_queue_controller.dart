import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../data/quran_audio_catalog.dart';
import 'offline_audio_manager.dart';
import 'quran_audio_download_url.dart';

enum AudioQueueStatus { idle, running, paused }

class AudioQueueItem {
  const AudioQueueItem({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.audioInfo,
    this.bitrate,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final QuranAudioInfo audioInfo;
  final int? bitrate;

  String get id => '$storageKey|$surah';
}

class AudioDownloadQueueController extends ChangeNotifier {
  AudioDownloadQueueController._();

  static final AudioDownloadQueueController instance =
      AudioDownloadQueueController._();

  final Queue<AudioQueueItem> _pending = Queue<AudioQueueItem>();
  final Set<String> _known = <String>{};
  AudioQueueItem? _active;
  AudioQueueStatus _status = AudioQueueStatus.idle;
  int _completedThisRun = 0;

  AudioQueueStatus get status => _status;
  AudioQueueItem? get active => _active;
  int get pendingCount => _pending.length;
  int get completedThisRun => _completedThisRun;
  bool get hasWork => _active != null || _pending.isNotEmpty;

  List<AudioQueueItem> get pending =>
      List<AudioQueueItem>.unmodifiable(_pending);

  void enqueueAll(Iterable<AudioQueueItem> items) {
    for (final item in items) {
      if (_known.add(item.id)) _pending.add(item);
    }
    if (_pending.isNotEmpty && _status == AudioQueueStatus.idle) {
      _status = AudioQueueStatus.paused;
    }
    notifyListeners();
  }

  void removePending(String storageKey, int surah) {
    final id = '$storageKey|$surah';
    _pending.removeWhere((item) => item.id == id);
    _known.remove(id);
    if (_pending.isEmpty && _active == null) {
      _status = AudioQueueStatus.idle;
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (_status == AudioQueueStatus.running) return;
    _status = AudioQueueStatus.running;
    notifyListeners();

    while (_status == AudioQueueStatus.running && _pending.isNotEmpty) {
      final item = _pending.removeFirst();
      _active = item;
      notifyListeners();
      final resolver = QuranAudioDownloadUrlResolver(
        item.audioInfo,
        bitrate: item.bitrate,
      );
      await OfflineAudioManager.instance.downloadSurah(
        storageKey: item.storageKey,
        surah: item.surah,
        verseCount: item.verseCount,
        urlForAyah: (ayah) => resolver.urlForVerse(item.surah, ayah),
      );
      final progress = OfflineAudioManager.instance.progressFor(
        item.storageKey,
        item.surah,
      );
      if (progress?.status == AudioDownloadStatus.completed) {
        _completedThisRun++;
        _known.remove(item.id);
      } else if (progress?.status == AudioDownloadStatus.paused) {
        _pending.addFirst(item);
      } else {
        // Failed jobs stay visible in Downloads but are not hot-looped.
        _known.remove(item.id);
      }
      _active = null;
      notifyListeners();
    }

    if (_pending.isEmpty) {
      _status = AudioQueueStatus.idle;
      _known.clear();
    } else if (_status == AudioQueueStatus.running) {
      _status = AudioQueueStatus.paused;
    }
    notifyListeners();
  }

  void pause() {
    if (_status != AudioQueueStatus.running) return;
    _status = AudioQueueStatus.paused;
    final item = _active;
    if (item != null) {
      OfflineAudioManager.instance.pauseDownload(item.storageKey, item.surah);
    }
    notifyListeners();
  }

  void clearPending() {
    for (final item in _pending) {
      _known.remove(item.id);
    }
    _pending.clear();
    if (_active == null) _status = AudioQueueStatus.idle;
    notifyListeners();
  }
}
