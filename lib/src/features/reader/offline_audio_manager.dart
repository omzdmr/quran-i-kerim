import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'offline_audio_pack_manifest.dart';

export 'offline_audio_pack_manifest.dart' show OfflineAudioPackReadiness;
import 'resumable_file_download.dart';

enum AudioNetworkKind { wifi, mobile, offline, other }

enum AudioDownloadStatus { downloading, paused, verifying, completed, failed }

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
    required this.readiness,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;
  final OfflineAudioPackReadiness readiness;

  bool get complete => readiness == OfflineAudioPackReadiness.ready;
  bool get partial =>
      readiness == OfflineAudioPackReadiness.incomplete ||
      readiness == OfflineAudioPackReadiness.needsRepair;
  bool get needsRepair => readiness == OfflineAudioPackReadiness.needsRepair;
}

class OfflineAudioSurah {
  const OfflineAudioSurah({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.downloadedAyahs,
    required this.bytes,
    required this.readiness,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;
  final OfflineAudioPackReadiness readiness;
}

class OfflineAudioManager extends ChangeNotifier {
  OfflineAudioManager._();

  static final OfflineAudioManager instance = OfflineAudioManager._();
  static const _intentStore = OfflineAudioPackIntentStore();

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
    final inspection = await _inspect(storageKey, surah);
    final manifest = inspection.manifest;
    final readiness = inspection.ayahBytes.isEmpty && !inspection.hasPartials
        ? OfflineAudioPackReadiness.notInstalled
        : manifest == null
        ? (inspection.ayahBytes.length >= verseCount
              ? OfflineAudioPackReadiness.needsRepair
              : OfflineAudioPackReadiness.incomplete)
        : manifest.matches(
            expectedStorageKey: storageKey,
            expectedSurah: surah,
            expectedVerseCount: verseCount,
            actualAyahBytes: inspection.ayahBytes,
            hasPartialFiles: inspection.hasPartials,
          )
        ? OfflineAudioPackReadiness.ready
        : OfflineAudioPackReadiness.needsRepair;
    return AudioSurahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
      downloadedAyahs: inspection.ayahBytes.length,
      bytes: inspection.totalBytes,
      readiness: readiness,
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
    await _intentStore.upsert(
      OfflineAudioPackIntent(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
      ),
    );
    final job = _DownloadJob();
    _jobs[key] = job;
    await _removeFilesKnownToBeDamaged(storageKey, surah, verseCount);
    var stats = await surahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
    );
    _progress[key] = _progressFrom(
      stats,
      AudioDownloadStatus.downloading,
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
        _progress[key] = _progressFrom(
          stats,
          AudioDownloadStatus.downloading,
        );
        notifyListeners();
      }

      if (job.cancelRequested) {
        await _deleteSurahInternal(storageKey, surah);
        await _intentStore.remove(storageKey, surah);
        _progress.remove(key);
      } else if (job.pauseRequested) {
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = _progressFrom(stats, AudioDownloadStatus.paused);
      } else {
        _progress[key] = _progressFrom(stats, AudioDownloadStatus.verifying);
        notifyListeners();
        await _publishManifest(storageKey, surah, verseCount);
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        if (!stats.complete) {
          throw const FileSystemException(
            'Offline audio pack verification failed',
          );
        }
        _progress[key] = _progressFrom(stats, AudioDownloadStatus.completed);
      }
    } catch (error) {
      stats = await surahStats(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
      );
      _progress[key] = _progressFrom(
        stats,
        AudioDownloadStatus.failed,
        error: '$error',
      );
    } finally {
      _jobs.remove(key);
      notifyListeners();
    }
  }

  AudioDownloadProgress _progressFrom(
    AudioSurahStats stats,
    AudioDownloadStatus status, {
    String? error,
  }) => AudioDownloadProgress(
    storageKey: stats.storageKey,
    surah: stats.surah,
    verseCount: stats.verseCount,
    downloadedAyahs: stats.downloadedAyahs,
    bytes: stats.bytes,
    status: status,
    error: error,
  );

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
    await _intentStore.remove(storageKey, surah);
    _progress.remove(_jobKey(storageKey, surah));
    notifyListeners();
  }

  Future<void> deleteSource(String storageKey) async {
    final root = await _root();
    final directory = Directory('${root.path}/${_safe(storageKey)}');
    if (await directory.exists()) await directory.delete(recursive: true);
    await _intentStore.removeSource(storageKey);
    _progress.removeWhere((key, _) => key.startsWith('$storageKey|'));
    notifyListeners();
  }

  Future<List<OfflineAudioSurah>> downloadedSurahs() async {
    final intents = <String, OfflineAudioPackIntent>{
      for (final intent in await _intentStore.load()) intent.id: intent,
    };
    final root = await _root();
    final found = <String, OfflineAudioSurah>{};
    await for (final sourceEntity in root.list()) {
      if (sourceEntity is! Directory) continue;
      final storageKey = sourceEntity.path.split(Platform.pathSeparator).last;
      await for (final surahEntity in sourceEntity.list()) {
        if (surahEntity is! Directory) continue;
        final name = surahEntity.path.split(Platform.pathSeparator).last;
        final surah = int.tryParse(name);
        if (surah == null) continue;
        final inspection = await _inspect(storageKey, surah);
        final manifest = inspection.manifest;
        final intent = intents['$storageKey|$surah'];
        final verseCount = manifest?.verseCount ?? intent?.verseCount ?? 0;
        if (inspection.ayahBytes.isEmpty &&
            !inspection.hasPartials &&
            intent == null) {
          continue;
        }
        final readiness = manifest != null &&
                manifest.matches(
                  expectedStorageKey: storageKey,
                  expectedSurah: surah,
                  expectedVerseCount: verseCount,
                  actualAyahBytes: inspection.ayahBytes,
                  hasPartialFiles: inspection.hasPartials,
                )
            ? OfflineAudioPackReadiness.ready
            : manifest != null || (verseCount > 0 && inspection.ayahBytes.length >= verseCount)
            ? OfflineAudioPackReadiness.needsRepair
            : OfflineAudioPackReadiness.incomplete;
        found['$storageKey|$surah'] = OfflineAudioSurah(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: inspection.ayahBytes.length,
          bytes: inspection.totalBytes,
          readiness: readiness,
        );
      }
    }
    for (final intent in intents.values) {
      found.putIfAbsent(
        intent.id,
        () => OfflineAudioSurah(
          storageKey: intent.storageKey,
          surah: intent.surah,
          verseCount: intent.verseCount,
          downloadedAyahs: 0,
          bytes: 0,
          readiness: OfflineAudioPackReadiness.incomplete,
        ),
      );
    }
    final result = found.values.toList()
      ..sort((a, b) {
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

  Future<void> _removeFilesKnownToBeDamaged(
    String storageKey,
    int surah,
    int verseCount,
  ) async {
    final inspection = await _inspect(storageKey, surah);
    final manifest = inspection.manifest;
    if (manifest == null) return;
    for (var ayah = 1; ayah <= verseCount; ayah++) {
      final expected = manifest.ayahBytes[ayah];
      final actual = inspection.ayahBytes[ayah];
      if (actual != null && expected != actual) {
        final file = await _verseFile(storageKey, surah, ayah);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<void> _publishManifest(
    String storageKey,
    int surah,
    int verseCount,
  ) async {
    final inspection = await _inspect(storageKey, surah);
    if (inspection.hasPartials || inspection.ayahBytes.length != verseCount) {
      throw const FileSystemException('Offline audio pack is incomplete');
    }
    for (var ayah = 1; ayah <= verseCount; ayah++) {
      if ((inspection.ayahBytes[ayah] ?? 0) <= 0) {
        throw const FileSystemException('Offline audio pack has a missing ayah');
      }
    }
    final directory = await _surahDirectory(storageKey, surah, create: true);
    final target = File('${directory.path}/pack_manifest_v1.json');
    final partial = File('${target.path}.part');
    await partial.writeAsString(
      OfflineAudioPackManifest(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        ayahBytes: inspection.ayahBytes,
        completedAt: DateTime.now().toUtc(),
      ).encode(),
      flush: true,
    );
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
  }

  Future<_AudioDirectoryInspection> _inspect(
    String storageKey,
    int surah,
  ) async {
    final directory = await _surahDirectory(storageKey, surah, create: false);
    if (!await directory.exists()) return const _AudioDirectoryInspection();
    final ayahBytes = <int, int>{};
    var hasPartials = false;
    OfflineAudioPackManifest? manifest;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name == 'pack_manifest_v1.json') {
        manifest = OfflineAudioPackManifest.decode(await entity.readAsString());
        continue;
      }
      if (name.endsWith('.part')) {
        hasPartials = true;
        continue;
      }
      final match = RegExp(r'^(\d{3})\.mp3$').firstMatch(name);
      if (match == null) continue;
      try {
        final length = await entity.length();
        if (length <= 0) {
          await entity.delete();
          continue;
        }
        ayahBytes[int.parse(match.group(1)!)] = length;
      } catch (_) {}
    }
    return _AudioDirectoryInspection(
      ayahBytes: Map<int, int>.unmodifiable(ayahBytes),
      hasPartials: hasPartials,
      manifest: manifest,
    );
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

class _AudioDirectoryInspection {
  const _AudioDirectoryInspection({
    this.ayahBytes = const <int, int>{},
    this.hasPartials = false,
    this.manifest,
  });

  final Map<int, int> ayahBytes;
  final bool hasPartials;
  final OfflineAudioPackManifest? manifest;

  int get totalBytes => ayahBytes.values.fold(0, (sum, value) => sum + value);
}

class _DownloadJob {
  bool pauseRequested = false;
  bool cancelRequested = false;
}
