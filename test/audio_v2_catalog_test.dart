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

  test('unverified Tamil audio is not exposed as a selectable source', () {
    final audio = quranAudioById('tamil_omar_brief_audio');
    final translation = translationById('tamil_omar_brief');

    expect(audio, isNull);
    expect(translation, isNotNull);
    expect(translation?.hasAudio, isFalse);
  });

  test('direct CDN catalog does not keep obsolete Arabic aliases', () {
    expect(quranAudioById('arabic_recitation_abdulbasit_mujawwad'), isNull);
    expect(quranAudioById('arabic_recitation_abdul_samad')?.providerKey, 'ar.abdulsamad');
    expect(quranAudioById('arabic_recitation_ibrahim_akhdar')?.providerKey, 'ar.ibrahimakhbar');
    expect(quranAudioById('arabic_recitation_parhizgar')?.providerKey, 'ar.parhizgar');
  });

  test('Kuliev Russian audio is tied to Kuliev Russian text', () {
    final audio = quranAudioById('russian_kuliev_audio');
    final translation = translationById('russian_kuliev');
    expect(audio?.sourceId, translation?.id);
    expect(audio?.providerKey, 'ru.kuliev-audio');
    expect(translation?.sourceKey, 'ru.kuliev');
    expect(translation?.hasAudio, isTrue);
  });

  test('Arabic reciters remain selectable with a translation active', () {
    final available = quranAudioForSource('russian_kuliev');
    expect(available.first.id, 'russian_kuliev_audio');
    expect(
      available.any((audio) => audio.id == 'arabic_recitation_husary'),
      isTrue,
    );

    final config = readerAudioConfigFor(
      'russian_kuliev',
      audioId: 'arabic_recitation_husary',
    );
    expect(config, isNotNull);
    expect(config!.id, 'arabic_recitation_husary');
    expect(config.urlForVerse(1, 1), contains('/ar.husary/1.mp3'));
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
