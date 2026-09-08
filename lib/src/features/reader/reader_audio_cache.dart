import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ReaderAudioCache {
  ReaderAudioCache._();

  static final ReaderAudioCache instance = ReaderAudioCache._();

  static const int maxCacheBytes = 100 * 1024 * 1024;
  static const int trimTargetBytes = 90 * 1024 * 1024;
  static const int _maxConcurrentPrefetches = 2;
  static const int _maxQueuedPrefetches = 24;

  final Map<String, Future<File>> _inFlight = <String, Future<File>>{};
  final Queue<_PrefetchTask> _prefetchQueue = Queue<_PrefetchTask>();
  final Set<String> _queuedKeys = <String>{};

  Directory? _cacheDirectory;
  int _activePrefetches = 0;
  Future<void>? _trimFuture;

  Future<File?> cachedFile(String cacheKey) async {
    final directory = await _directory();
    final file = File('${directory.path}/$cacheKey.mp3');
    if (!await file.exists()) return null;
    if (await file.length() <= 0) {
      await _deleteQuietly(file);
      return null;
    }
    await _touch(file);
    return file;
  }

  Future<File> ensureCached({required String cacheKey, required String url}) {
    return _inFlight.putIfAbsent(cacheKey, () async {
      final existing = await cachedFile(cacheKey);
      if (existing != null) return existing;

      final directory = await _directory();
      final file = File('${directory.path}/$cacheKey.mp3');
      final partial = File('${file.path}.part');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 15);
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.acceptHeader, 'audio/mpeg,*/*;q=0.8');
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Audio download failed with ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }
        final sink = partial.openWrite();
        try {
          await response.pipe(sink);
        } finally {
          await sink.close();
        }
        if (await partial.length() <= 0) {
          throw const FileSystemException('Audio cache file is empty');
        }
        if (await file.exists()) await _deleteQuietly(file);
        final completed = await partial.rename(file.path);
        await _touch(completed);
        unawaited(_scheduleTrim());
        return completed;
      } catch (_) {
        if (await partial.exists()) {
          await _deleteQuietly(partial);
        }
        rethrow;
      } finally {
        client.close(force: true);
        _inFlight.remove(cacheKey);
      }
    });
  }

  Future<void> prefetchWindow({
    required String sourceId,
    required int surah,
    required int startAyah,
    required int verseCount,
    required String Function(int ayah) urlForAyah,
    int windowSize = 4,
  }) async {
    final safeStart = startAyah.clamp(1, verseCount).toInt();
    final endAyah = (safeStart + windowSize - 1).clamp(1, verseCount).toInt();

    final newest = <_PrefetchTask>[];
    for (var ayah = safeStart; ayah <= endAyah; ayah++) {
      final key = cacheKeyFor(sourceId, surah, ayah);
      final existing = await cachedFile(key);
      if (existing != null || _inFlight.containsKey(key) || _queuedKeys.contains(key)) {
        continue;
      }
      newest.add(_PrefetchTask(cacheKey: key, url: urlForAyah(ayah)));
    }

    for (final task in newest.reversed) {
      _prefetchQueue.addFirst(task);
      _queuedKeys.add(task.cacheKey);
    }

    while (_prefetchQueue.length > _maxQueuedPrefetches) {
      final removed = _prefetchQueue.removeLast();
      _queuedKeys.remove(removed.cacheKey);
    }

    _pumpPrefetchQueue();
  }

  String cacheKeyFor(String sourceId, int surah, int ayah) {
    final safeSource = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safeSource}_${surah.toString().padLeft(3, '0')}_${ayah.toString().padLeft(3, '0')}';
  }

  Future<void> clearTemporaryCache() async {
    final directory = await _directory();
    if (!await directory.exists()) return;
    _prefetchQueue.clear();
    _queuedKeys.clear();
    await for (final entity in directory.list()) {
      if (entity is File) {
        await _deleteQuietly(entity);
      }
    }
  }

  void _pumpPrefetchQueue() {
    while (_activePrefetches < _maxConcurrentPrefetches &&
        _prefetchQueue.isNotEmpty) {
      final task = _prefetchQueue.removeFirst();
      _queuedKeys.remove(task.cacheKey);
      _activePrefetches++;
      unawaited(
        ensureCached(cacheKey: task.cacheKey, url: task.url)
            .catchError((_) => File(''))
            .whenComplete(() {
              _activePrefetches--;
              _pumpPrefetchQueue();
            }),
      );
    }
  }

  Future<void> _scheduleTrim() {
    final active = _trimFuture;
    if (active != null) return active;
    final future = _trimIfNeeded();
    _trimFuture = future;
    return future.whenComplete(() {
      if (identical(_trimFuture, future)) _trimFuture = null;
    });
  }

  Future<void> _trimIfNeeded() async {
    final directory = await _directory();
    final entries = <_CachedAudioFile>[];
    var totalBytes = 0;

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      try {
        final stat = await entity.stat();
        totalBytes += stat.size;
        entries.add(
          _CachedAudioFile(
            file: entity,
            size: stat.size,
            lastUsed: stat.modified,
          ),
        );
      } catch (_) {
        // A concurrent cache write may briefly change the directory listing.
      }
    }

    if (totalBytes <= maxCacheBytes) return;
    entries.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));

    for (final entry in entries) {
      if (totalBytes <= trimTargetBytes) break;
      final key = _cacheKeyFromPath(entry.file.path);
      if (_inFlight.containsKey(key)) continue;
      await _deleteQuietly(entry.file);
      totalBytes -= entry.size;
    }
  }

  String _cacheKeyFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.endsWith('.mp3') ? name.substring(0, name.length - 4) : name;
  }

  Future<void> _touch(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Playback can continue even if the filesystem refuses a timestamp touch.
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Managed cache cleanup is best-effort.
    }
  }

  Future<Directory> _directory() async {
    final cached = _cacheDirectory;
    if (cached != null) return cached;
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/reader_audio_cache_v1');
    await directory.create(recursive: true);
    _cacheDirectory = directory;
    return directory;
  }
}

class _PrefetchTask {
  const _PrefetchTask({required this.cacheKey, required this.url});

  final String cacheKey;
  final String url;
}

class _CachedAudioFile {
  const _CachedAudioFile({
    required this.file,
    required this.size,
    required this.lastUsed,
  });

  final File file;
  final int size;
  final DateTime lastUsed;
}
