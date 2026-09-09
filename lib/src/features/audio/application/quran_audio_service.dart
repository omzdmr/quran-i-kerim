import 'package:audio_service/audio_service.dart';

import 'quran_audio_handler.dart';

/// Process-wide entry point for background Quran playback.
class QuranAudioService {
  QuranAudioService._();

  static final QuranAudioService instance = QuranAudioService._();

  QuranAudioHandler? _handler;

  QuranAudioHandler get handler {
    final value = _handler;
    if (value == null) {
      throw StateError('QuranAudioService.initialize() must be called first.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_handler != null) return;
    _handler = await AudioService.init<QuranAudioHandler>(
      builder: QuranAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.omzdmr.quran_i_kerim.audio',
        androidNotificationChannelName: 'Kur’an sesli okuma',
        androidNotificationOngoing: true,
      ),
    );
  }
}
