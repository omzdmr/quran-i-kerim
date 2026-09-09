import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local-first cache for human-recorded Quran/translation audio files.
///
/// Cached files are keyed by source edition + ayah identity. Playback callers
/// always receive a local file URI after [getOrDownload] succeeds, so the
/// player can continue offline without changing its queue model.
class QuranAudioFileCache {
  QuranAudioFileCache({
    required Directory rootDirectory,
    HttpClient? httpClient,
  })  : _rootDirectory = rootDirectory,
        _httpClient = httpClient ?? HttpClient();

  final Directory _rootDirectory;
  final HttpClient _httpClient;

  static Future<QuranAudioFileCache> openDefault({HttpClient? httpClient}) async {
    final support = await getApplicationSupportDirectory();
    return QuranAudioFileCache(
      rootDirectory: Directory('${support.path}/audio-v21'),
      httpClient: httpClient,
    );
  }

  Future<Uri?> cachedUri({
    required String sourceIdentifier,
    required int surah,
    required int ayah,
  }) async {
    final directory = Directory(
      '${_rootDirectory.path}/${_safeSegment(sourceIdentifier)}/$surah',
    );
    if (!await directory.exists()) return null;

    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.startsWith('$ayah.') && !name.endsWith('.part') && await entity.length() > 0) {
        return entity.uri;
      }
    }
    return null;
  }

  Future<Uri> getOrDownload({
    required Uri remoteUri,
    required String sourceIdentifier,
    required int surah,
    required int ayah,
  }) async {
    final existing = await cachedUri(
      sourceIdentifier: sourceIdentifier,
      surah: surah,
      ayah: ayah,
    );
    if (existing != null) return existing;

    final target = _fileFor(
      sourceIdentifier: sourceIdentifier,
      surah: surah,
      ayah: ayah,
      extension: _extensionFrom(remoteUri),
    );
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.part');
    if (await temporary.exists()) {
      await temporary.delete();
    }

    try {
      final request = await _httpClient.getUrl(remoteUri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw HttpException(
          'Audio download failed with ${response.statusCode}',
          uri: remoteUri,
        );
      }

      final sink = temporary.openWrite();
      await response.pipe(sink);

      if (!await temporary.exists() || await temporary.length() == 0) {
        throw const FileSystemException('Downloaded audio file is empty.');
      }

      if (await target.exists()) {
        await target.delete();
      }
      return (await temporary.rename(target.path)).uri;
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
  }

  Future<void> remove({
    required String sourceIdentifier,
    required int surah,
    required int ayah,
  }) async {
    final directory = Directory(
      '${_rootDirectory.path}/${_safeSegment(sourceIdentifier)}/$surah',
    );
    if (!await directory.exists()) return;

    await for (final entity in directory.list()) {
      if (entity is File && entity.path.split(Platform.pathSeparator).last.startsWith('$ayah.')) {
        await entity.delete();
      }
    }
  }

  Future<void> clear() async {
    if (await _rootDirectory.exists()) {
      await _rootDirectory.delete(recursive: true);
    }
  }

  void close() => _httpClient.close(force: true);

  File _fileFor({
    required String sourceIdentifier,
    required int surah,
    required int ayah,
    String extension = 'mp3',
  }) {
    final source = _safeSegment(sourceIdentifier);
    return File('${_rootDirectory.path}/$source/$surah/$ayah.$extension');
  }

  static String _extensionFrom(Uri uri) {
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final dot = segment.lastIndexOf('.');
    if (dot <= 0 || dot == segment.length - 1) return 'mp3';
    final candidate = segment.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(candidate) ? candidate : 'mp3';
  }

  static String _safeSegment(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }
}
