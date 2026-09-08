import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ReaderAudioCache {
  ReaderAudioCache._();

  static final ReaderAudioCache instance = ReaderAudioCache._();

  final Map<String, Future<File>> _inFlight = <String, Future<File>>{};
  Directory? _cacheDirectory;

  Future<File?> cachedFile(String cacheKey) async {
    final directory = await _directory();
    final file = File('${directory.path}/$cacheKey.mp3');
    if (!await file.exists()) return null;
    if (await file.length() <= 0) {
      await _deleteQuietly(file);
      return null;
    }
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
        return await partial.rename(file.path);
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
    final endAyah = (startAyah + windowSize - 1).clamp(1, verseCount).toInt();
    for (var ayah = startAyah; ayah <= endAyah; ayah++) {
      unawaited(
        ensureCached(
          cacheKey: cacheKeyFor(sourceId, surah, ayah),
          url: urlForAyah(ayah),
        ).catchError((_) => File('')),
      );
    }
  }

  String cacheKeyFor(String sourceId, int surah, int ayah) {
    final safeSource = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safeSource}_${surah.toString().padLeft(3, '0')}_${ayah.toString().padLeft(3, '0')}';
  }

  Future<void> clearTemporaryCache() async {
    final directory = await _directory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File) {
        await _deleteQuietly(entity);
      }
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temporary cache cleanup is best-effort.
    }
  }

  Future<Directory> _directory() async {
    final cached = _cacheDirectory;
    if (cached != null) return cached;
    final root = await getTemporaryDirectory();
    final directory = Directory('${root.path}/reader_audio_cache');
    await directory.create(recursive: true);
    _cacheDirectory = directory;
    return directory;
  }
}
