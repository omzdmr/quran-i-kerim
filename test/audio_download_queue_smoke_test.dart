import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/audio_download_queue_controller.dart';

void main() {
  final audio = quranAudioCatalog.first;

  AudioQueueItem item(int surah) => AudioQueueItem(
        storageKey: audio.id,
        surah: surah,
        verseCount: 7,
        audioInfo: audio,
      );

  test('queue deduplicates packs and preserves FIFO order', () {
    final queue = AudioDownloadQueueController();
    queue.enqueueAll([item(1), item(2), item(1)]);
    expect(queue.pending.map((entry) => entry.surah), [1, 2]);
    expect(queue.pendingCount, 2);
    expect(queue.status, AudioQueueStatus.paused);
  });

  test('pending work can be removed and cleared without touching files', () {
    final queue = AudioDownloadQueueController();
    queue.enqueueAll([item(1), item(2)]);
    queue.removePending(audio.id, 1);
    expect(queue.pending.map((entry) => entry.surah), [2]);
    queue.clearPending();
    expect(queue.pending, isEmpty);
    expect(queue.status, AudioQueueStatus.idle);
  });

  test('source cancellation removes only matching pending packs', () {
    final queue = AudioDownloadQueueController();
    queue.enqueueAll([
      item(1),
      item(2),
      AudioQueueItem(
        storageKey: 'other',
        surah: 3,
        verseCount: 7,
        audioInfo: audio,
      ),
    ]);
    queue.cancelSource(audio.id);
    expect(queue.pending, hasLength(1));
    expect(queue.pending.single.storageKey, 'other');
    expect(queue.pending.single.surah, 3);
  });

  test('single pack cancellation keeps unrelated work queued', () {
    final queue = AudioDownloadQueueController();
    queue.enqueueAll([item(1), item(2)]);
    queue.cancelItem(audio.id, 1);
    expect(queue.pending.map((entry) => entry.surah), [2]);
  });

  test('preflight can pause before dequeuing when policy changes', () async {
    final queue = AudioDownloadQueueController();
    queue.enqueueAll([item(1), item(2)]);
    await queue.start(canStart: (_) async => false);
    expect(queue.status, AudioQueueStatus.paused);
    expect(queue.pending.map((entry) => entry.surah), [1, 2]);
    expect(queue.active, isNull);
  });
}
