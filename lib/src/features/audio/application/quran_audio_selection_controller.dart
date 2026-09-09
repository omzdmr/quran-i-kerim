import '../domain/quran_audio_source.dart';
import '../domain/quran_audio_track.dart';
import 'quran_audio_playback_coordinator.dart';

typedef QuranAudioCatalogLoader = Future<QuranAudioCatalog> Function();
typedef QuranAudioSelectedQueueLoader = Future<List<QuranAudioTrack>> Function({
  required QuranAudioSource source,
  required List<QuranAudioAyahRequest> ayahs,
  int initialIndex,
  bool autoplay,
});

/// Small application-layer bridge used by presentation code to browse human
/// audio alternatives and send the chosen edition into the local-first
/// playback pipeline.
///
/// The controller never manufactures audio sources and never falls back to
/// TTS. Every selectable source must already exist in the verified catalog.
class QuranAudioSelectionController {
  QuranAudioSelectionController({
    required QuranAudioCatalogLoader loadCatalog,
    required QuranAudioSelectedQueueLoader loadAyahs,
  })  : _loadCatalog = loadCatalog,
        _loadAyahs = loadAyahs;

  factory QuranAudioSelectionController.fromCoordinator({
    required QuranAudioCatalogLoader loadCatalog,
    required QuranAudioPlaybackCoordinator coordinator,
  }) {
    return QuranAudioSelectionController(
      loadCatalog: loadCatalog,
      loadAyahs: coordinator.loadAyahs,
    );
  }

  final QuranAudioCatalogLoader _loadCatalog;
  final QuranAudioSelectedQueueLoader _loadAyahs;

  QuranAudioCatalog? _catalog;
  QuranAudioSource? _selectedSource;

  QuranAudioCatalog? get catalog => _catalog;
  QuranAudioSource? get selectedSource => _selectedSource;

  Future<QuranAudioCatalog> ensureCatalog() async {
    final existing = _catalog;
    if (existing != null) return existing;
    final loaded = await _loadCatalog();
    _catalog = loaded;
    return loaded;
  }

  Future<List<QuranAudioSource>> alternatives({
    required String languageCode,
    required QuranAudioKind kind,
  }) async {
    final currentCatalog = await ensureCatalog();
    return currentCatalog.alternatives(
      languageCode: languageCode,
      kind: kind,
    );
  }

  Future<QuranAudioSource> select({required String identifier}) async {
    final currentCatalog = await ensureCatalog();
    for (final source in currentCatalog.sources) {
      if (source.identifier == identifier) {
        _selectedSource = source;
        return source;
      }
    }
    throw StateError('Unknown human audio source: $identifier');
  }

  Future<QuranAudioSource> selectPreferred({
    required String languageCode,
    required QuranAudioKind kind,
    String? preferredIdentifier,
  }) async {
    final options = await alternatives(languageCode: languageCode, kind: kind);
    if (options.isEmpty) {
      throw StateError(
        'No human audio source for $languageCode/${kind.name}.',
      );
    }

    if (preferredIdentifier != null) {
      for (final option in options) {
        if (option.identifier == preferredIdentifier) {
          _selectedSource = option;
          return option;
        }
      }
    }

    final fallback = options.first;
    _selectedSource = fallback;
    return fallback;
  }

  Future<List<QuranAudioTrack>> loadSelectedAyahs({
    required List<QuranAudioAyahRequest> ayahs,
    int initialIndex = 0,
    bool autoplay = false,
  }) async {
    final source = _selectedSource;
    if (source == null) {
      throw StateError('Select a human audio source before playback.');
    }
    return _loadAyahs(
      source: source,
      ayahs: ayahs,
      initialIndex: initialIndex,
      autoplay: autoplay,
    );
  }
}
