import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_defaults.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';

void main() {
  setUp(() {
    registerDiscoveredTranslations(const <TranslationInfo>[]);
  });

  tearDown(() {
    registerDiscoveredTranslations(const <TranslationInfo>[]);
  });

  test('supported onboarding languages map to real curated Quran sources', () {
    expect(onboardingDefaultQuranSourceForLanguage('tr'), bundledTurkishTranslationId);
    expect(onboardingDefaultQuranSourceForLanguage('en'), englishTranslationId);
    expect(onboardingDefaultQuranSourceForLanguage('ar'), arabicOriginalSourceId);
    expect(onboardingDefaultQuranSourceForLanguage('az'), 'azeri_musayev');
    expect(onboardingDefaultQuranSourceForLanguage('ru'), 'russian_kuliev');

    for (final language in const ['tr', 'en', 'az', 'ru']) {
      final source = onboardingDefaultTranslationForLanguage(language);
      expect(source, isNotNull, reason: language);
      expect(source!.available, isTrue, reason: language);
      expect(source.languageCode, language, reason: language);
    }
    expect(onboardingDefaultTranslationForLanguage('ar'), isNull);
  });

  test('unsupported onboarding language keeps the existing safe fallback', () {
    expect(onboardingDefaultQuranSourceForLanguage('de'), englishTranslationId);
    expect(onboardingDefaultTranslationForLanguage('de')?.id, englishTranslationId);
  });

  test('reading goals reuse the real reading-plan presets', () {
    expect(onboardingReadingPlanChoices, ReadingPlanPreset.values);
  });

  test('reciter choices reuse Arabic recitations from the audio catalog', () {
    final choices = onboardingReciterChoices;
    expect(choices, isNotEmpty);
    expect(
      choices.every(
        (audio) =>
            audio.kind == QuranAudioKind.recitation &&
            audio.sourceId == arabicOriginalSourceId,
      ),
      isTrue,
    );
    expect(
      choices.map((audio) => audio.id).toSet().length,
      choices.length,
    );
  });
}
