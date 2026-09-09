import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/application/quran_audio_playback_coordinator.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_source.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_track.dart';

void main() {
  const source = QuranAudioSource(
    identifier: 'tr.test',
    languageCode: 'tr',
    name: 'İnsan Sesi',
    englishName: 'Human Voice',
    kind: QuranAudioKind.translation,
    providerName: 'Provider',
    providerUri: Uri.parse('https://example.com'),
    termsUri: Uri.parse('https://example.com/terms'),
  );

  test('cache hit never resolves or downloads from network', () async {
    var resolveCalls = 0;
    var downloadCalls = 0;
    List<QuranAudioTrack>? queued;

    final coordinator = QuranAudioPlaybackCoordinator(
      cachedAudio: ({required sourceIdentifier, required surah, required ayah}) async =>
          Uri.file('/cache/$sourceIdentifier/$surah/$ayah.mp3'),
      resolveRemote: ({required source, required surah, required ayah}) async {
        resolveCalls++;
        return Uri.parse('https://cdn.example/$surah/$ayah.mp3');
      },
      cacheRemote: ({required remoteUri, required sourceIdentifier, required surah, required ayah}) async {
        downloadCalls++;
        return Uri.file('/cache/$sourceIdentifier/$surah/$ayah.mp3');
      },
      loadQueue: (tracks, {initialIndex = 0, autoplay = false}) async {
        queued = tracks;
      },
    );

    final tracks = await coordinator.loadAyahs(
      source: source,
      ayahs: const <QuranAudioAyahRequest>[
        QuranAudioAyahRequest(surah: 1, ayah: 1, surahName: 'Fâtiha'),
      ],
      autoplay: true,
    );

    expect(resolveCalls, 0);
    expect(downloadCalls, 0);
    expect(tracks.single.uri.scheme, 'file');
    expect(tracks.single.translation, isTrue);
    expect(tracks.single.voiceName, 'İnsan Sesi');
    expect(queued, hasLength(1));
  });

  test('cache miss resolves, downloads, then queues only local URIs', () async {
    var resolveCalls = 0;
    var downloadCalls = 0;
    var queuedInitialIndex = -1;
    var queuedAutoplay = false;
    List<QuranAudioTrack>? queued;

    final coordinator = QuranAudioPlaybackCoordinator(
      cachedAudio: ({required sourceIdentifier, required surah, required ayah}) async => null,
      resolveRemote: ({required source, required surah, required ayah}) async {
        resolveCalls++;
        return Uri.parse('https://cdn.example/${source.identifier}/$surah/$ayah.mp3');
      },
      cacheRemote: ({required remoteUri, required sourceIdentifier, required surah, required ayah}) async {
        downloadCalls++;
        expect(remoteUri.scheme, 'https');
        return Uri.file('/cache/$sourceIdentifier/$surah/$ayah.mp3');
      },
      loadQueue: (tracks, {initialIndex = 0, autoplay = false}) async {
        queued = tracks;
        queuedInitialIndex = initialIndex;
        queuedAutoplay = autoplay;
      },
    );

    final tracks = await coordinator.loadAyahs(
      source: source,
      ayahs: const <QuranAudioAyahRequest>[
        QuranAudioAyahRequest(surah: 2, ayah: 255, surahName: 'Bakara'),
        QuranAudioAyahRequest(surah: 2, ayah: 256, surahName: 'Bakara'),
      ],
      initialIndex: 99,
      autoplay: true,
    );

    expect(resolveCalls, 2);
    expect(downloadCalls, 2);
    expect(tracks, hasLength(2));
    expect(tracks.every((track) => track.uri.scheme == 'file'), isTrue);
    expect(tracks.first.id, 'tr.test:2:255');
    expect(queued, hasLength(2));
    expect(queuedInitialIndex, 1);
    expect(queuedAutoplay, isTrue);
  });

  test('rejects non-local cache result before queueing', () async {
    var queueCalls = 0;
    final coordinator = QuranAudioPlaybackCoordinator(
      cachedAudio: ({required sourceIdentifier, required surah, required ayah}) async =>
          Uri.parse('https://should-not-stream.example/$ayah.mp3'),
      resolveRemote: ({required source, required surah, required ayah}) async =>
          Uri.parse('https://unused.example/$ayah.mp3'),
      cacheRemote: ({required remoteUri, required sourceIdentifier, required surah, required ayah}) async =>
          Uri.file('/unused.mp3'),
      loadQueue: (tracks, {initialIndex = 0, autoplay = false}) async {
        queueCalls++;
      },
    );

    expect(
      () => coordinator.loadAyahs(
        source: source,
        ayahs: const <QuranAudioAyahRequest>[
          QuranAudioAyahRequest(surah: 1, ayah: 1, surahName: 'Fâtiha'),
        ],
      ),
      throwsStateError,
    );
    expect(queueCalls, 0);
  });
}
