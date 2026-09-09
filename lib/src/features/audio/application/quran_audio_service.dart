import 'package:audio_service/audio_service.dart';

import '../data/alquran_cloud_audio_catalog_repository.dart';
import '../data/alquran_cloud_ayah_audio_resolver.dart';
import '../data/quran_audio_file_cache.dart';
import 'quran_audio_handler.dart';
import 'quran_audio_playback_coordinator.dart';
import 'quran_audio_selection_controller.dart';

/// Process-wide entry point for background Quran playback.
///
/// This is also the Audio v2.1 composition root. Presentation code reaches the
/// verified human-audio catalog through [selectionController], while every
/// selected ayah still flows through resolver -> local cache -> local file
/// queue before the background player sees it. No TTS path exists here.
class QuranAudioService {
  QuranAudioService._();

  static final QuranAudioService instance = QuranAudioService._();

  QuranAudioHandler? _handler;
  QuranAudioSelectionController? _selectionController;
  AlQuranCloudAudioCatalogRepository? _catalogRepository;
  AlQuranCloudAyahAudioResolver? _resolver;
  QuranAudioFileCache? _cache;

  QuranAudioHandler get handler {
    final value = _handler;
    if (value == null) {
      throw StateError('QuranAudioService.initialize() must be called first.');
    }
    return value;
  }

  QuranAudioSelectionController get selectionController {
    final value = _selectionController;
    if (value == null) {
      throw StateError('QuranAudioService.initialize() must be called first.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_handler != null && _selectionController != null) return;

    final audioHandler = _handler ??= await AudioService.init<QuranAudioHandler>(
      builder: QuranAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.omzdmr.quran_i_kerim.audio',
        androidNotificationChannelName: 'Kur’an sesli okuma',
        androidNotificationOngoing: true,
      ),
    );

    final catalogRepository =
        _catalogRepository ??= AlQuranCloudAudioCatalogRepository();
    final resolver = _resolver ??= AlQuranCloudAyahAudioResolver();
    final cache = _cache ??= await QuranAudioFileCache.openDefault();
    final coordinator = QuranAudioPlaybackCoordinator.fromServices(
      resolver: resolver,
      cache: cache,
      handler: audioHandler,
    );

    _selectionController ??= QuranAudioSelectionController.fromCoordinator(
      loadCatalog: catalogRepository.load,
      coordinator: coordinator,
    );
  }
}
