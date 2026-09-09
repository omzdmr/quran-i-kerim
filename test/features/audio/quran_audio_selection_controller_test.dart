import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/application/quran_audio_playback_coordinator.dart';
import 'package:quran_i_kerim/src/features/audio/application/quran_audio_selection_controller.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_source.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_track.dart';

QuranAudioSource source({
  required String identifier,
  required String languageCode,
  required String name,
  required QuranAudioKind kind,
}) {
  return QuranAudioSource(
    identifier: identifier,
    languageCode: languageCode,
    name: name,
    englishName: name,
    kind: kind,
    providerName: 'Test Provider',
    providerUri: Uri.parse('https://example.test/provider'),
    termsUri: Uri.parse('https://example.test/terms'),
  );
}

void main() {
  final englishB = source(
    identifier: 'en.b',
    languageCode: 'en',
    name: 'Beta',
    kind: QuranAudioKind.quran,
  );
  final englishA = source(
    identifier: 'en.a',
    languageCode: 'en',
    name: 'Alpha',
    kind: QuranAudioKind.quran,
  );
  final englishTranslation = source(
    identifier: 'en.translation',
    languageCode: 'en',
    name: 'English Translation',
    kind: QuranAudioKind.translation,
  );
  final turkish = source(
    identifier: 'tr.a',
    languageCode: 'tr',
    name: 'Turkish Voice',
    kind: QuranAudioKind.quran,
  );
  final catalog = QuranAudioCatalog(<QuranAudioSource>[
    englishB,
    englishA,
    englishTranslation,
    turkish,
  ]);

  test('loads catalog once and exposes sorted language/kind alternatives', () async {
    var loads = 0;
    final controller = QuranAudioSelectionController(
      loadCatalog: () async {
        loads += 1;
        return catalog;
      },
      loadAyahs: ({
        required source,
        required ayahs,
        int initialIndex = 0,
        bool autoplay = false,
      }) async => const <QuranAudioTrack>[],
    );

    final first = await controller.alternatives(
      languageCode: 'en',
      kind: QuranAudioKind.quran,
    );
    final second = await controller.alternatives(
      languageCode: 'en',
      kind: QuranAudioKind.translation,
    );

    expect(first.map((item) => item.identifier), <String>['en.a', 'en.b']);
    expect(second.single.identifier, 'en.translation');
    expect(loads, 1);
  });

  test('selectPreferred honors exact human edition then falls back deterministically', () async {
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => catalog,
      loadAyahs: ({
        required source,
        required ayahs,
        int initialIndex = 0,
        bool autoplay = false,
      }) async => const <QuranAudioTrack>[],
    );

    final preferred = await controller.selectPreferred(
      languageCode: 'en',
      kind: QuranAudioKind.quran,
      preferredIdentifier: 'en.b',
    );
    expect(preferred.identifier, 'en.b');
    expect(controller.selectedSource?.identifier, 'en.b');

    final fallback = await controller.selectPreferred(
      languageCode: 'en',
      kind: QuranAudioKind.quran,
      preferredIdentifier: 'missing',
    );
    expect(fallback.identifier, 'en.a');
  });

  test('rejects an identifier not present in the approved catalog', () async {
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => catalog,
      loadAyahs: ({
        required source,
        required ayahs,
        int initialIndex = 0,
        bool autoplay = false,
      }) async => const <QuranAudioTrack>[],
    );

    expect(
      () => controller.select(identifier: 'invented.tts'),
      throwsA(isA<StateError>()),
    );
  });

  test('requires selection before playback and forwards the chosen source', () async {
    QuranAudioSource? forwardedSource;
    List<QuranAudioAyahRequest>? forwardedAyahs;
    int? forwardedIndex;
    bool? forwardedAutoplay;
    var queueCalls = 0;

    final expectedTrack = QuranAudioTrack(
      id: 'en.b:2:255',
      uri: Uri.parse('file:///tmp/2_255.mp3'),
      surah: 2,
      ayah: 255,
      surahName: 'Al-Baqarah',
      voiceName: 'Beta',
      languageCode: 'en',
    );
    final controller = QuranAudioSelectionController(
      loadCatalog: () async => catalog,
      loadAyahs: ({
        required source,
        required ayahs,
        int initialIndex = 0,
        bool autoplay = false,
      }) async {
        queueCalls += 1;
        forwardedSource = source;
        forwardedAyahs = ayahs;
        forwardedIndex = initialIndex;
        forwardedAutoplay = autoplay;
        return <QuranAudioTrack>[expectedTrack];
      },
    );

    final request = const QuranAudioAyahRequest(
      surah: 2,
      ayah: 255,
      surahName: 'Al-Baqarah',
    );

    expect(
      () => controller.loadSelectedAyahs(ayahs: <QuranAudioAyahRequest>[request]),
      throwsA(isA<StateError>()),
    );
    expect(queueCalls, 0);

    await controller.select(identifier: 'en.b');
    final tracks = await controller.loadSelectedAyahs(
      ayahs: <QuranAudioAyahRequest>[request],
      initialIndex: 3,
      autoplay: true,
    );

    expect(queueCalls, 1);
    expect(forwardedSource?.identifier, 'en.b');
    expect(forwardedAyahs?.single.ayah, 255);
    expect(forwardedIndex, 3);
    expect(forwardedAutoplay, isTrue);
    expect(tracks.single.id, expectedTrack.id);
  });
}
