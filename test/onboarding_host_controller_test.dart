import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_controller.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_defaults.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_host_controller.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_selection_applier.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<OnboardingHostController> createHost({
    Future<void> Function()? markCompleted,
  }) async {
    final settings = AppSettings();
    await settings.load();
    return OnboardingHostController(
      applier: OnboardingSelectionApplier(settings: settings),
      flow: OnboardingController(markCompleted: markCompleted),
    );
  }

  test('applies each selection in flow order and completes last', () async {
    var completed = false;
    final host = await createHost(
      markCompleted: () async {
        completed = true;
      },
    );
    addTearDown(host.dispose);

    host.selectLanguage('ru');
    expect(await host.applyCurrentAndNext(), isFalse);
    expect(host.flow.step, OnboardingStep.translation);

    host.selectQuranSource(bundledTurkishTranslationId);
    expect(await host.applyCurrentAndNext(), isFalse);
    expect(host.flow.step, OnboardingStep.readingGoal);

    final plan = onboardingReadingPlanChoices.last;
    host.selectReadingGoal(plan);
    expect(await host.applyCurrentAndNext(), isFalse);
    expect(host.flow.step, OnboardingStep.reciter);

    final reciter = onboardingReciterChoices.last;
    host.selectReciter(reciter);
    expect(await host.applyCurrentAndNext(), isTrue);
    expect(completed, isTrue);

    final restored = AppSettings();
    await restored.load();
    expect(restored.locale?.languageCode, 'ru');
    expect(restored.selectedQuranSourceId, bundledTurkishTranslationId);
    expect(restored.selectedAudioSourceFor(arabicOriginalSourceId), reciter.id);
    final planSnapshot = await const ReadingPlanStore().load();
    expect(planSnapshot.active?.preset.id, plan.id);
  });

  test('rejects unavailable Quran sources and non-reciter audio', () async {
    final host = await createHost();
    addTearDown(host.dispose);

    expect(
      () => host.selectQuranSource('missing-source'),
      throwsArgumentError,
    );

    final translationAudio = quranAudioCatalog.firstWhere(
      (audio) => audio.kind == QuranAudioKind.translation,
    );
    expect(
      () => host.selectReciter(translationAudio),
      throwsArgumentError,
    );
  });
}
