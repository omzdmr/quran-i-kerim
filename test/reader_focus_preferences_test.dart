import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_focus_controller.dart';
import 'package:quran_i_kerim/src/features/reader/reader_focus_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ReaderFocusPreferencesStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('auto-scroll speed persists across Reader sessions', () async {
    await store.saveAutoScrollSpeed(ReaderAutoScrollSpeed.fast);

    expect(
      await store.loadAutoScrollSpeed(),
      ReaderAutoScrollSpeed.fast,
    );
  });

  test('unknown auto-scroll speed safely falls back to normal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReaderFocusPreferencesStore.autoScrollSpeedKey: 'future-speed',
    });

    expect(
      await store.loadAutoScrollSpeed(),
      ReaderAutoScrollSpeed.normal,
    );
  });
}
