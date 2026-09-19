import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_selection_applier.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('onboarding reciter follows the selected translation into Reader', () async {
    final settings = AppSettings();
    await settings.load();
    await settings.setSelectedQuranSource('russian_kuliev');
    final applier = OnboardingSelectionApplier(settings: settings);
    final husary = quranAudioById('arabic_recitation_husary')!;

    await applier.applyReciter(husary);

    expect(
      settings.selectedAudioSourceFor(arabicOriginalSourceId),
      husary.id,
    );
    expect(settings.selectedAudioSourceFor('russian_kuliev'), husary.id);
    expect(
      quranAudioForSource('russian_kuliev').any(
        (audio) => audio.id == settings.selectedAudioSourceFor('russian_kuliev'),
      ),
      isTrue,
    );
  });
}
