import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/quran_audio_download_url.dart';

void main() {
  test('download resolver preserves quranEnc surah and ayah addressing', () {
    final audio = quranAudioCatalog.firstWhere(
      (item) => item.provider == QuranAudioProvider.quranEnc,
    );
    final resolver = QuranAudioDownloadUrlResolver(audio);
    expect(
      resolver.urlForVerse(2, 5),
      'https://d.quranenc.com/data/audio/${audio.providerKey}/002005.mp3',
    );
  });

  test('download resolver honors stored bitrate for Islamic Network packs', () {
    final audio = quranAudioCatalog.firstWhere(
      (item) => item.provider == QuranAudioProvider.islamicNetwork,
    );
    final resolver = QuranAudioDownloadUrlResolver(audio, bitrate: 64);
    expect(
      resolver.urlForVerse(2, 1),
      'https://cdn.islamic.network/quran/audio/64/${audio.providerKey}/8.mp3',
    );
  });
}
