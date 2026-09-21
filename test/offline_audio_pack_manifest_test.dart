import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/offline_audio_pack_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const manifest = OfflineAudioPackManifest(
    storageKey: 'reciter_128',
    surah: 1,
    verseCount: 3,
    ayahBytes: <int, int>{1: 120, 2: 140, 3: 160},
    completedAt: DateTime.utc(2026, 9, 21),
  );

  test('manifest round trip preserves the atomic pack boundary', () {
    final restored = OfflineAudioPackManifest.decode(manifest.encode());

    expect(restored, isNotNull);
    expect(restored!.storageKey, 'reciter_128');
    expect(restored.verseCount, 3);
    expect(restored.totalBytes, 420);
    expect(
      restored.matches(
        expectedStorageKey: 'reciter_128',
        expectedSurah: 1,
        expectedVerseCount: 3,
        actualAyahBytes: const <int, int>{1: 120, 2: 140, 3: 160},
        hasPartialFiles: false,
      ),
      isTrue,
    );
  });

  test('missing, changed, partial or cross-edition payload is never ready', () {
    expect(
      manifest.matches(
        expectedStorageKey: 'reciter_128',
        expectedSurah: 1,
        expectedVerseCount: 3,
        actualAyahBytes: const <int, int>{1: 120, 2: 140},
        hasPartialFiles: false,
      ),
      isFalse,
    );
    expect(
      manifest.matches(
        expectedStorageKey: 'reciter_128',
        expectedSurah: 1,
        expectedVerseCount: 3,
        actualAyahBytes: const <int, int>{1: 120, 2: 999, 3: 160},
        hasPartialFiles: false,
      ),
      isFalse,
    );
    expect(
      manifest.matches(
        expectedStorageKey: 'reciter_128',
        expectedSurah: 1,
        expectedVerseCount: 3,
        actualAyahBytes: const <int, int>{1: 120, 2: 140, 3: 160},
        hasPartialFiles: true,
      ),
      isFalse,
    );
    expect(
      manifest.matches(
        expectedStorageKey: 'another_reciter',
        expectedSurah: 1,
        expectedVerseCount: 3,
        actualAyahBytes: const <int, int>{1: 120, 2: 140, 3: 160},
        hasPartialFiles: false,
      ),
      isFalse,
    );
  });

  test('corrupt or future manifests fail closed', () {
    expect(OfflineAudioPackManifest.decode('{broken'), isNull);
    expect(
      OfflineAudioPackManifest.decode(
        '{"formatVersion":99,"storageKey":"x","surah":1,"verseCount":1,"completedAt":"2026-09-21T00:00:00Z","ayahBytes":{"1":12}}',
      ),
      isNull,
    );
  });

  test('download intent survives restore without media payload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = OfflineAudioPackIntentStore();
    const first = OfflineAudioPackIntent(
      storageKey: 'reciter_128',
      surah: 2,
      verseCount: 286,
    );

    await store.upsert(first);
    await store.upsert(first);

    final restored = await store.load();
    expect(restored, hasLength(1));
    expect(restored.single.storageKey, 'reciter_128');
    expect(restored.single.surah, 2);
    expect(restored.single.verseCount, 286);

    await store.remove('reciter_128', 2);
    expect(await store.load(), isEmpty);
  });

  test('intent parser rejects unsafe or unusable records', () {
    expect(OfflineAudioPackIntent.decode('{}'), isNull);
    expect(
      OfflineAudioPackIntent.decode(
        '{"storageKey":"voice","surah":0,"verseCount":7}',
      ),
      isNull,
    );
  });
}
