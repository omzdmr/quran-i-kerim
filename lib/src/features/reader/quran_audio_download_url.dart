import 'package:quran/quran.dart' as quran;

import '../../data/quran_audio_catalog.dart';

class QuranAudioDownloadUrlResolver {
  const QuranAudioDownloadUrlResolver(this.audio, {this.bitrate});

  final QuranAudioInfo audio;
  final int? bitrate;

  String urlForVerse(int surah, int ayah) {
    if (audio.provider == QuranAudioProvider.quranEnc) {
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      return 'https://d.quranenc.com/data/audio/${audio.providerKey}/$s$a.mp3';
    }
    var absolute = ayah;
    for (var previous = 1; previous < surah; previous++) {
      absolute += quran.getVerseCount(previous);
    }
    final resolvedBitrate = bitrate ?? audio.bitrate ?? 128;
    return 'https://cdn.islamic.network/quran/audio/$resolvedBitrate/${audio.providerKey}/$absolute.mp3';
  }
}
