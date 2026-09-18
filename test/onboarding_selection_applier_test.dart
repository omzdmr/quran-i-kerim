import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_defaults.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_selection_applier.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('applies language and Quran source independently', () async {
    final settings = AppSettings();
    await settings.load();
    final applier = OnboardingSelectionApplier(settings: settings);

    await applier.applyLanguage('RU');
    await applier.applyQuranSource(bundledTurkishTranslationId);

    final restored = AppSettings();
    await restored.load();
    expect(restored.locale?.languageCode, 'ru');
    expect(restored.selectedQuranSourceId, bundledTurkishTranslationId);
    expect(restored.quranSourceWasUserSelected, isTrue);
  });

  test('starts the selected real reading plan preset', () async {
    final settings = AppSettings();
    await settings.load();
    final applier = OnboardingSelectionApplier(settings: settings);
    final preset = onboardingReadingPlanChoices.first;

    await applier.applyReadingGoal(preset);

    final snapshot = await const ReadingPlanStore().load();
    expect(snapshot.active?.preset.id, preset.id);
  });

  test('persists an Arabic reciter and rejects translation audio', () async {
    final settings = AppSettings();
    await settings.load();
    final applier = OnboardingSelectionApplier(settings: settings);
    final reciter = onboardingReciterChoices.first;

    await applier.applyReciter(reciter);

    final restored = AppSettings();
    await restored.load();
    expect(restored.selectedAudioSourceFor(arabicOriginalSourceId), reciter.id);

    final translationAudio = quranAudioCatalog.firstWhere(
      (audio) => audio.kind == QuranAudioKind.translation,
    );
    await expectLater(
      applier.applyReciter(translationAudio),
      throwsArgumentError,
    );
  });
}
