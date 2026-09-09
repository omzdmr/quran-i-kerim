import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_reading_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reading history keeps latest unique position first', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    await repo.record(surah: 2, ayah: 255, sourceId: 'arabic_original');
    await repo.record(surah: 36, ayah: 1, sourceId: 'arabic_original');
    await repo.record(surah: 2, ayah: 255, sourceId: 'tr_rwwad');

    final items = await repo.load();
    expect(items.length, 2);
    expect(items.first.surah, 2);
    expect(items.first.ayah, 255);
    expect(items.first.sourceId, 'tr_rwwad');
    expect(items[1].surah, 36);
  });

  test('reading history caps local history size', () async {
    final repo = ReaderReadingHistoryRepository.instance;
    for (var i = 0; i < 60; i++) {
      await repo.record(surah: (i % 60) + 1, ayah: i + 1, sourceId: 'x');
    }
    expect((await repo.load()).length, ReaderReadingHistoryRepository.maxEntries);
  });
}
