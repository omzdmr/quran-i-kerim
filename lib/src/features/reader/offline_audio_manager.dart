import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'resumable_file_download.dart';

enum AudioNetworkKind { wifi, mobile, offline, other }

enum AudioDownloadStatus { downloading, paused, completed, failed }

class AudioDownloadProgress {
  const AudioDownloadProgress({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.downloadedAyahs,
    required this.bytes,
    required this.status,
    this.error,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;
  final AudioDownloadStatus status;
  final String? error;

  double get fraction => verseCount <= 0 ? 0 : downloadedAyahs / verseCount;
}

class AudioSurahStats {
  const AudioSurahStats({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.downloadedAyahs,
    required this.bytes,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;

  bool get complete => verseCount > 0 && downloadedAyahs >= verseCount;
  bool get partial => downloadedAyahs > 0 && !complete;
}

class OfflineAudioSurah {
  const OfflineAudioSurah({
    required this.storageKey,
    required this.surah,
    required this.downloadedAyahs,
    required this.bytes,
  });

  final String storageKey;
  final int surah;
  final int downloadedAyahs;
  final int bytes;
}

class OfflineAudioManager extends ChangeNotifier {
  OfflineAudioManager._();

  static final OfflineAudioManager instance = OfflineAudioManager._();

  final Map<String, AudioDownloadProgress> _progress =
      <String, AudioDownloadProgress>{};
  final Map<String, _DownloadJob> _jobs = <String, _DownloadJob>{};
  Directory? _rootDirectory;

  String _jobKey(String storageKey, int surah) => '$storageKey|$surah';

  AudioDownloadProgress? progressFor(String storageKey, int surah) =>
      _progress[_jobKey(storageKey, surah)];

  Future<AudioNetworkKind> currentNetworkKind() async {
    final values = await Connectivity().checkConnectivity();
    if (values.contains(ConnectivityResult.wifi) ||
        values.contains(ConnectivityResult.ethernet)) {
      return AudioNetworkKind.wifi;
    }
    if (values.contains(ConnectivityResult.mobile)) {
      return AudioNetworkKind.mobile;
    }
    if (values.isEmpty ||
        values.every((value) => value == ConnectivityResult.none)) {
      return AudioNetworkKind.offline;
    }
    return AudioNetworkKind.other;
  }

  Future<File?> offlineFile({
    required String storageKey,
    required int surah,
    required int ayah,
  }) async {
    final file = await _verseFile(storageKey, surah, ayah);
    if (!await file.exists()) return null;
    if (await file.length() <= 0) {
      await file.delete();
      return null;
    }
    return file;
  }

  Future<bool> isVerseDownloaded({
    required String storageKey,
    required int surah,
    required int ayah,
  }) async =>
      await offlineFile(storageKey: storageKey, surah: surah, ayah: ayah) !=
      null;

  Future<AudioSurahStats> surahStats({
    required String storageKey,
    required int surah,
    required int verseCount,
  }) async {
    final directory = await _surahDirectory(storageKey, surah, create: false);
    if (!await directory.exists()) {
      return AudioSurahStats(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        downloadedAyahs: 0,
        bytes: 0,
      );
    }
    var count = 0;
    var bytes = 0;
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      try {
        final length = await entity.length();
        if (length <= 0) continue;
        count++;
        bytes += length;
      } catch (_) {}
    }
    return AudioSurahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
      downloadedAyahs: count,
      bytes: bytes,
    );
  }

  Future<void> downloadSurah({
    required String storageKey,
    required int surah,
    required int verseCount,
    required String Function(int ayah) urlForAyah,
  }) async {
    final key = _jobKey(storageKey, surah);
    if (_jobs.containsKey(key)) return;
    final job = _DownloadJob();
    _jobs[key] = job;
    var stats = await surahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
    );
    _progress[key] = AudioDownloadProgress(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
      downloadedAyahs: stats.downloadedAyahs,
      bytes: stats.bytes,
      status: AudioDownloadStatus.downloading,
    );
    notifyListeners();

    try {
      for (var ayah = 1; ayah <= verseCount; ayah++) {
        if (job.cancelRequested || job.pauseRequested) break;
        final existing = await offlineFile(
          storageKey: storageKey,
          surah: surah,
          ayah: ayah,
        );
        if (existing == null) {
          final result = await _downloadOne(
            file: await _verseFile(storageKey, surah, ayah),
            url: urlForAyah(ayah),
            job: job,
          );
          if (result == ResumableDownloadResult.interrupted) break;
        }
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.downloading,
        );
        notifyListeners();
      }

      if (job.cancelRequested) {
        await _deleteSurahInternal(storageKey, surah);
        _progress.remove(key);
      } else if (job.pauseRequested) {
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.paused,
        );
      } else {
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.completed,
        );
      }
    } catch (error) {
      stats = await surahStats(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
      );
      _progress[key] = AudioDownloadProgress(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        downloadedAyahs: stats.downloadedAyahs,
        bytes: stats.bytes,
        status: AudioDownloadStatus.failed,
        error: '$error',
      );
    } finally {
      _jobs.remove(key);
      notifyListeners();
    }
  }

  void pauseDownload(String storageKey, int surah) {
    _jobs[_jobKey(storageKey, surah)]?.pauseRequested = true;
  }

  void cancelDownload(String storageKey, int surah) {
    _jobs[_jobKey(storageKey, surah)]?.cancelRequested = true;
  }

  Future<void> deleteSurah(String storageKey, int surah) async {
    final job = _jobs[_jobKey(storageKey, surah)];
    if (job != null) job.cancelRequested = true;
    await _deleteSurahInternal(storageKey, surah);
    _progress.remove(_jobKey(storageKey, surah));
    notifyListeners();
  }

  Future<void> deleteSource(String storageKey) async {
    final root = await _root();
    final directory = Directory('${root.path}/${_safe(storageKey)}');
    if (await directory.exists()) await directory.delete(recursive: true);
    _progress.removeWhere((key, _) => key.startsWith('$storageKey|'));
    notifyListeners();
  }

  Future<List<OfflineAudioSurah>> downloadedSurahs() async {
    final root = await _root();
    final result = <OfflineAudioSurah>[];
    await for (final sourceEntity in root.list()) {
      if (sourceEntity is! Directory) continue;
      final storageKey = sourceEntity.path.split(Platform.pathSeparator).last;
      await for (final surahEntity in sourceEntity.list()) {
        if (surahEntity is! Directory) continue;
        final name = surahEntity.path.split(Platform.pathSeparator).last;
        final surah = int.tryParse(name);
        if (surah == null) continue;
        var count = 0;
        var bytes = 0;
        await for (final file in surahEntity.list()) {
          if (file is! File || !file.path.endsWith('.mp3')) continue;
          try {
            final length = await file.length();
            if (length <= 0) continue;
            count++;
            bytes += length;
          } catch (_) {}
        }
        if (count > 0) {
          result.add(
            OfflineAudioSurah(
              storageKey: storageKey,
              surah: surah,
              downloadedAyahs: count,
              bytes: bytes,
            ),
          );
        }
      }
    }
    result.sort((a, b) {
      final source = a.storageKey.compareTo(b.storageKey);
      return source != 0 ? source : a.surah.compareTo(b.surah);
    });
    return result;
  }

  Future<int> totalBytes() async {
    var bytes = 0;
    for (final item in await downloadedSurahs()) {
      bytes += item.bytes;
    }
    return bytes;
  }

  int estimateSurahBytes({required int verseCount, int? bitrate}) {
    final kbps = bitrate ?? 96;
    const averageSecondsPerAyah = 10;
    return ((verseCount * averageSecondsPerAyah * kbps * 1000) / 8).round();
  }

  Future<ResumableDownloadResult> _downloadOne({
    required File file,
    required String url,
    required _DownloadJob job,
  }) => downloadResumableFile(
    target: file,
    uri: Uri.parse(url),
    shouldInterrupt: () => job.cancelRequested || job.pauseRequested,
  );

  Future<void> _deleteSurahInternal(String storageKey, int surah) async {
    final directory = await _surahDirectory(storageKey, surah, create: false);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<File> _verseFile(String storageKey, int surah, int ayah) async {
    final directory = await _surahDirectory(storageKey, surah, create: true);
    return File('${directory.path}/${ayah.toString().padLeft(3, '0')}.mp3');
  }

  Future<Directory> _surahDirectory(
    String storageKey,
    int surah, {
    required bool create,
  }) async {
    final root = await _root();
    final directory = Directory(
      '${root.path}/${_safe(storageKey)}/${surah.toString().padLeft(3, '0')}',
    );
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<Directory> _root() async {
    final cached = _rootDirectory;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/offline_audio_v1');
    await directory.create(recursive: true);
    _rootDirectory = directory;
    return directory;
  }
}

class _DownloadJob {
  bool pauseRequested = false;
  bool cancelRequested = false;
}
