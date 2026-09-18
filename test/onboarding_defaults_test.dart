import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_defaults.dart';

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
}
