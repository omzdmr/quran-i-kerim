import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/application/quran_audio_reader_bridge.dart';
import 'package:quran_i_kerim/src/features/audio/application/quran_audio_selection_controller.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_source.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_track.dart';

void main() {
  final arabicA = QuranAudioSource(
    identifier: 'ar.voice.a',
    languageCode: 'ar',
    name: 'Voice A',
    englishName: 'Voice A',
    kind: QuranAudioKind.quran,
    providerName: 'Provider',
    providerUri: Uri.parse('https://example.com'),
    termsUri: Uri.parse('https://example.com/terms'),
  );
  final arabicB = QuranAudioSource(
    identifier: 'ar.voice.b',
    languageCode: 'ar',
    name: 'Voice B',
    englishName: 'Voice B',
    kind: QuranAudioKind.quran,
    providerName: 'Provider',
    providerUri: Uri.parse('https://example.com'),
    termsUri: Uri.parse('https://example.com/terms'),
  );
  final turkish = QuranAudioSource(
    identifier: 'tr.translation.human',
    languageCode: 'tr',
    name: 'Türkçe İnsan Kaydı',
    englishName: 'Turkish Human Recording',
    kind: QuranAudioKind.translation,
    providerName: 'Provider',
    providerUri: Uri.parse('https://example.com'),
    termsUri: Uri.parse('https://example.com/terms'),
  );

  test('lists alternatives for reader mode without inventing sources', () async {
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => QuranAudioCatalog([arabicB, turkish, arabicA]),
      loadAyahs: ({required source, required ayahs, initialIndex = 0, autoplay = false}) async => const <QuranAudioTrack>[],
    );
    final bridge = QuranAudioReaderBridge(controller);

    final quranVoices = await bridge.alternatives(translation: false);
    final translationVoices = await bridge.alternatives(translation: true);

    expect(quranVoices.map((source) => source.identifier), ['ar.voice.a', 'ar.voice.b']);
    expect(translationVoices.map((source) => source.identifier), ['tr.translation.human']);
  });

  test('plays normalized selected ayahs with preferred human source', () async {
    QuranAudioSource? loadedSource;
    List<int>? loadedAyahs;
    bool? loadedAutoplay;
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => QuranAudioCatalog([arabicA, arabicB, turkish]),
      loadAyahs: ({required source, required ayahs, initialIndex = 0, autoplay = false}) async {
        loadedSource = source;
        loadedAyahs = ayahs.map((ayah) => ayah.ayah).toList();
        loadedAutoplay = autoplay;
        return const <QuranAudioTrack>[];
      },
    );
    final bridge = QuranAudioReaderBridge(controller);

    await bridge.playSelection(
      surah: 29,
      surahName: 'Ankebût',
      ayahs: const [10, 8, 10, 9],
      translation: false,
      preferredIdentifier: 'ar.voice.b',
    );

    expect(loadedSource?.identifier, 'ar.voice.b');
    expect(loadedAyahs, [8, 9, 10]);
    expect(loadedAutoplay, isTrue);
  });

  test('translation reader mode selects only matching human translation audio', () async {
    QuranAudioSource? loadedSource;
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => QuranAudioCatalog([arabicA, turkish]),
      loadAyahs: ({required source, required ayahs, initialIndex = 0, autoplay = false}) async {
        loadedSource = source;
        return const <QuranAudioTrack>[];
      },
    );
    final bridge = QuranAudioReaderBridge(controller);

    await bridge.playSelection(
      surah: 1,
      surahName: 'Fâtiha',
      ayahs: const [1],
      translation: true,
    );

    expect(loadedSource?.identifier, 'tr.translation.human');
    expect(loadedSource?.kind, QuranAudioKind.translation);
  });
}
