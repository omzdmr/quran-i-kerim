import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_audio_sheet.dart';

void main() {
  test('Alafasy exposes only verified selectable bitrates', () {
    final audio = quranAudioById('arabic_recitation_alafasy');
    expect(audio, isNotNull);
    expect(quranAudioBitrates(audio!), <int>[64, 128]);
  });

  test('selected bitrate changes URL and persistent storage identity', () {
    final config = readerAudioConfigFor(
      arabicOriginalSourceId,
      audioId: 'arabic_recitation_alafasy',
      bitrate: 64,
    );
    expect(config, isNotNull);
    expect(config!.bitrate, 64);
    expect(config.cacheId, 'arabic_recitation_alafasy_64');
    expect(config.urlForVerse(1, 1), contains('/audio/64/ar.alafasy/1.mp3'));
  });
}
