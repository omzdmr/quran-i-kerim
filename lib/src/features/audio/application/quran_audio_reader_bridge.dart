import '../domain/quran_audio_source.dart';
import '../domain/quran_audio_track.dart';
import 'quran_audio_playback_coordinator.dart';
import 'quran_audio_selection_controller.dart';

/// Presentation-facing Audio v2.1 bridge for Quran Reader selections.
///
/// It keeps Reader code free from provider/cache details: the Reader only says
/// which ayahs are selected and whether it wants Quran recitation or a human
/// translation recording. Source discovery and playback still go through the
/// verified human-audio catalog and the local-first playback pipeline.
class QuranAudioReaderBridge {
  QuranAudioReaderBridge(this._controller);

  final QuranAudioSelectionController _controller;

  Future<List<QuranAudioSource>> alternatives({
    required bool translation,
    String translationLanguageCode = 'tr',
  }) {
    return _controller.alternatives(
      languageCode: translation ? translationLanguageCode : 'ar',
      kind: translation ? QuranAudioKind.translation : QuranAudioKind.quran,
    );
  }

  Future<List<QuranAudioTrack>> playSelection({
    required int surah,
    required String surahName,
    required Iterable<int> ayahs,
    required bool translation,
    String translationLanguageCode = 'tr',
    String? preferredIdentifier,
  }) async {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }

    final normalizedAyahs = ayahs.toSet().toList()..sort();
    if (normalizedAyahs.isEmpty) {
      throw ArgumentError.value(ayahs, 'ayahs', 'At least one ayah is required.');
    }
    if (normalizedAyahs.any((ayah) => ayah < 1)) {
      throw RangeError('Ayah numbers must be positive.');
    }

    await _controller.selectPreferred(
      languageCode: translation ? translationLanguageCode : 'ar',
      kind: translation ? QuranAudioKind.translation : QuranAudioKind.quran,
      preferredIdentifier: preferredIdentifier,
    );

    return _controller.loadSelectedAyahs(
      ayahs: [
        for (final ayah in normalizedAyahs)
          QuranAudioAyahRequest(
            surah: surah,
            ayah: ayah,
            surahName: surahName,
          ),
      ],
      autoplay: true,
    );
  }
}
