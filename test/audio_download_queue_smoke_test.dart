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
}
