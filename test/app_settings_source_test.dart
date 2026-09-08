import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy Arabic reader mode migrates to the Arabic source ID', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_mode': 'arabic',
    });

    final settings = AppSettings();
    await settings.load();

    expect(settings.selectedQuranSourceId, arabicOriginalSourceId);
    expect(settings.readerUsesArabic, isTrue);
  });

  test('selected Quran source persists independently of app locale', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = AppSettings();
    await settings.load();

    await settings.setLocale(const Locale('ru'));
    await settings.setSelectedQuranSource(bundledTurkishTranslationId);

    final restored = AppSettings();
    await restored.load();
    expect(restored.locale?.languageCode, 'ru');
    expect(restored.selectedQuranSourceId, bundledTurkishTranslationId);
    expect(restored.readerUsesArabic, isFalse);
  });
}
