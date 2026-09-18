import '../../../data/quran_audio_catalog.dart';
import '../../../data/translation_catalog.dart';
import '../../plans/reading_plan.dart';

/// Maps supported app UI languages to a real Quran source already present in
/// the curated catalogue. Onboarding can use this without inventing a second
/// translation catalogue or coupling UI language to the user's later choice.
String onboardingDefaultQuranSourceForLanguage(String languageCode) {
  return switch (languageCode.trim().toLowerCase()) {
    'ar' => arabicOriginalSourceId,
    'az' => 'azeri_musayev',
    'en' => englishTranslationId,
    'ru' => 'russian_kuliev',
    'tr' => bundledTurkishTranslationId,
    _ => defaultQuranSourceForLanguage(languageCode),
  };
}

/// Returns only a curated, currently available source. This keeps onboarding
/// selections grounded in the same catalogue used by the reader/download UI.
TranslationInfo? onboardingDefaultTranslationForLanguage(String languageCode) {
  final sourceId = onboardingDefaultQuranSourceForLanguage(languageCode);
  if (sourceId == arabicOriginalSourceId) return null;
  final source = translationById(sourceId);
  return source != null && source.available ? source : null;
}

/// Reading goals are the real plan presets used by [ReadingPlanStore].
/// Onboarding should start one of these instead of persisting a parallel goal.
List<ReadingPlanPreset> get onboardingReadingPlanChoices =>
    List<ReadingPlanPreset>.unmodifiable(ReadingPlanPreset.values);

/// Reciter choices come from the same curated audio catalogue used by Reader.
/// Only Arabic recitation entries are exposed; translation audio is a separate
/// concern and remains independent from the UI/meal language selection.
List<QuranAudioInfo> get onboardingReciterChoices =>
    List<QuranAudioInfo>.unmodifiable(
      quranAudioCatalog.where(
        (audio) =>
            audio.kind == QuranAudioKind.recitation &&
            audio.sourceId == arabicOriginalSourceId,
      ),
    );
