import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('essential Reader preset restores as a persistent experience choice', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
      'reader_text_size': 24.0,
      'reader_line_spacing': 'compact',
    });

    final settings = AppSettings();
    await settings.load();

    expect(settings.readerExperiencePreset, ReaderExperiencePreset.essential);
    expect(settings.essentialReaderEnabled, isTrue);
    expect(settings.readerTextSize, 24);
    expect(settings.readerContentTextSize, 32);
    expect(settings.arabicFontSize, 32);
    expect(settings.translationFontSize, 32);
    expect(settings.arabicLineHeight, 2.02);
    expect(settings.translationLineHeight, 1.66);
    expect(settings.minimumInterfaceTextScale, 1.16);
  });

  test('turning the preset off restores custom Reader choices unchanged', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_text_size': 27.0,
      'reader_line_spacing': 'normal',
    });
    final settings = AppSettings();
    await settings.load();

    await settings.setReaderExperiencePreset(ReaderExperiencePreset.essential);
    expect(settings.readerContentTextSize, 32);

    await settings.setReaderExperiencePreset(ReaderExperiencePreset.standard);
    final prefs = await SharedPreferences.getInstance();

    expect(settings.readerTextSize, 27);
    expect(settings.readerContentTextSize, 27);
    expect(settings.readerLineSpacing, ReaderLineSpacing.normal);
    expect(prefs.getString('reader_experience_preset_v1'), 'standard');
  });

  test('essential preset never shrinks an already larger custom size', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
      'reader_text_size': 38.0,
      'reader_line_spacing': 'relaxed',
    });

    final settings = AppSettings();
    await settings.load();

    expect(settings.readerTextSize, 38);
    expect(settings.readerContentTextSize, 38);
    expect(settings.readerLineSpacing, ReaderLineSpacing.relaxed);
  });

  test('backup restore rehydrates the same Essential Reader experience', () async {
    final settings = AppSettings();
    await settings.load();
    await settings.setReaderExperiencePreset(ReaderExperiencePreset.essential);

    const adapter = SharedPreferencesBackupAdapter();
    final sections = await adapter.captureSections();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);

    final restored = AppSettings();
    await restored.load();

    expect(restored.readerExperiencePreset, ReaderExperiencePreset.essential);
    expect(restored.readerContentTextSize, 32);
  });

  test('unknown stored preset safely falls back to standard', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'future-mode',
    });

    final settings = AppSettings();
    await settings.load();

    expect(settings.readerExperiencePreset, ReaderExperiencePreset.standard);
    expect(settings.essentialReaderEnabled, isFalse);
    expect(settings.minimumInterfaceTextScale, 1);
  });
}
