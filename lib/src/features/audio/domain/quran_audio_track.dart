import 'package:audio_service/audio_service.dart';

/// A single human-recorded Quran or translation audio item.
///
/// The model intentionally carries only playback metadata. Source catalog and
/// licensing decisions stay outside the player so the playback layer can work
/// equally with streamed or already-cached local files.
class QuranAudioTrack {
  const QuranAudioTrack({
    required this.id,
    required this.uri,
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.voiceName,
    required this.languageCode,
    this.translation = false,
    this.duration,
  });

  final String id;
  final Uri uri;
  final int surah;
  final int ayah;
  final String surahName;
  final String voiceName;
  final String languageCode;
  final bool translation;
  final Duration? duration;

  String get reference => '$surah:$ayah';

  MediaItem toMediaItem() => MediaItem(
        id: id,
        title: '$surahName $reference',
        artist: voiceName,
        album: translation ? 'Kuran Meali' : 'Kur’an-ı Kerim',
        duration: duration,
        extras: <String, Object>{
          'uri': uri.toString(),
          'surah': surah,
          'ayah': ayah,
          'languageCode': languageCode,
          'translation': translation,
        },
      );
}
