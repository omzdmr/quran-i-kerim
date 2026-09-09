import '../data/alquran_cloud_ayah_audio_resolver.dart';
import '../data/quran_audio_file_cache.dart';
import '../domain/quran_audio_source.dart';
import '../domain/quran_audio_track.dart';
import 'quran_audio_handler.dart';

typedef CachedAudioLookup = Future<Uri?> Function({
  required String sourceIdentifier,
  required int surah,
  required int ayah,
});

typedef RemoteAudioResolver = Future<Uri> Function({
  required QuranAudioSource source,
  required int surah,
  required int ayah,
});

typedef AudioCacheWriter = Future<Uri> Function({
  required Uri remoteUri,
  required String sourceIdentifier,
  required int surah,
  required int ayah,
});

typedef AudioQueueLoader = Future<void> Function(
  List<QuranAudioTrack> tracks, {
  int initialIndex,
  bool autoplay,
});

/// Local-first bridge between the approved human-audio catalog and playback.
///
/// Every ayah is resolved in this order:
/// 1. existing local file,
/// 2. provider API URL,
/// 3. download into the app-owned cache,
/// 4. queue a [QuranAudioTrack] that points only at the local file URI.
///
/// This deliberately keeps the player independent of network availability.
class QuranAudioPlaybackCoordinator {
  QuranAudioPlaybackCoordinator({
    required CachedAudioLookup cachedAudio,
    required RemoteAudioResolver resolveRemote,
    required AudioCacheWriter cacheRemote,
    required AudioQueueLoader loadQueue,
  })  : _cachedAudio = cachedAudio,
        _resolveRemote = resolveRemote,
        _cacheRemote = cacheRemote,
        _loadQueue = loadQueue;

  factory QuranAudioPlaybackCoordinator.fromServices({
    required AlQuranCloudAyahAudioResolver resolver,
    required QuranAudioFileCache cache,
    required QuranAudioHandler handler,
  }) {
    return QuranAudioPlaybackCoordinator(
      cachedAudio: cache.cachedUri,
      resolveRemote: resolver.resolve,
      cacheRemote: cache.getOrDownload,
      loadQueue: handler.loadTracks,
    );
  }

  final CachedAudioLookup _cachedAudio;
  final RemoteAudioResolver _resolveRemote;
  final AudioCacheWriter _cacheRemote;
  final AudioQueueLoader _loadQueue;

  Future<QuranAudioTrack> prepareTrack({
    required QuranAudioSource source,
    required int surah,
    required int ayah,
    required String surahName,
  }) async {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }
    if (ayah < 1) {
      throw RangeError.range(ayah, 1, null, 'ayah');
    }

    var localUri = await _cachedAudio(
      sourceIdentifier: source.identifier,
      surah: surah,
      ayah: ayah,
    );

    if (localUri == null) {
      final remoteUri = await _resolveRemote(
        source: source,
        surah: surah,
        ayah: ayah,
      );
      localUri = await _cacheRemote(
        remoteUri: remoteUri,
        sourceIdentifier: source.identifier,
        surah: surah,
        ayah: ayah,
      );
    }

    if (localUri.scheme != 'file') {
      throw StateError('Audio cache must return a local file URI.');
    }

    return QuranAudioTrack(
      id: '${source.identifier}:$surah:$ayah',
      uri: localUri,
      surah: surah,
      ayah: ayah,
      surahName: surahName,
      voiceName: source.displayName,
      languageCode: source.languageCode,
      translation: source.isTranslation,
    );
  }

  Future<List<QuranAudioTrack>> loadAyahs({
    required QuranAudioSource source,
    required List<QuranAudioAyahRequest> ayahs,
    int initialIndex = 0,
    bool autoplay = false,
  }) async {
    if (ayahs.isEmpty) {
      await _loadQueue(
        const <QuranAudioTrack>[],
        initialIndex: 0,
        autoplay: false,
      );
      return const <QuranAudioTrack>[];
    }

    final tracks = <QuranAudioTrack>[];
    for (final ayah in ayahs) {
      tracks.add(
        await prepareTrack(
          source: source,
          surah: ayah.surah,
          ayah: ayah.ayah,
          surahName: ayah.surahName,
        ),
      );
    }

    final safeIndex = initialIndex.clamp(0, tracks.length - 1).toInt();
    await _loadQueue(
      List<QuranAudioTrack>.unmodifiable(tracks),
      initialIndex: safeIndex,
      autoplay: autoplay,
    );
    return List<QuranAudioTrack>.unmodifiable(tracks);
  }
}

class QuranAudioAyahRequest {
  const QuranAudioAyahRequest({
    required this.surah,
    required this.ayah,
    required this.surahName,
  });

  final int surah;
  final int ayah;
  final String surahName;
}
