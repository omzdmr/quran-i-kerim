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

  test('current Islamic Network reciter keys and qualities are exposed', () {
    final sudais = quranAudioById('arabic_recitation_sudais');
    final shuraim = quranAudioById('arabic_recitation_shuraim');
    final basfar = quranAudioById('arabic_recitation_abdullah_basfar');

    expect(sudais?.providerKey, 'ar.abdurrahmaansudais');
    expect(quranAudioBitrates(sudais!), <int>[64, 192]);
    expect(shuraim?.providerKey, 'ar.saoodshuraym');
    expect(quranAudioBitrates(shuraim!), <int>[64]);
    expect(quranAudioBitrates(basfar!), <int>[32, 64, 192]);
  });

  test('Tamil human audio is tied to its exact QuranEnc text source', () {
    final audio = quranAudioById('tamil_omar_brief_audio');
    final translation = translationById('tamil_omar_brief');

    expect(audio, isNotNull);
    expect(audio?.provider, QuranAudioProvider.quranEnc);
    expect(audio?.providerKey, 'tamil_omar_brief');
    expect(audio?.sourceId, translation?.id);
    expect(translation?.hasAudio, isTrue);
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
