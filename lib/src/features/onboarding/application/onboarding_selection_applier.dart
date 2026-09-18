import 'package:flutter/widgets.dart';

import '../../../data/quran_audio_catalog.dart';
import '../../../data/translation_catalog.dart';
import '../../../settings/app_settings.dart';
import '../../plans/reading_plan.dart';
import '../../plans/reading_plan_store.dart';

/// Applies onboarding choices through the same persistence APIs used by the
/// rest of the app. UI language and Quran source remain independent choices.
class OnboardingSelectionApplier {
  const OnboardingSelectionApplier({
    required AppSettings settings,
    ReadingPlanStore readingPlanStore = const ReadingPlanStore(),
  }) : _settings = settings,
       _readingPlanStore = readingPlanStore;

  final AppSettings _settings;
  final ReadingPlanStore _readingPlanStore;

  Future<void> applyLanguage(String languageCode) async {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) return;
    await _settings.setLocale(Locale(code));
  }

  Future<void> applyQuranSource(String sourceId) =>
      _settings.setSelectedQuranSource(sourceId);

  Future<void> applyReadingGoal(ReadingPlanPreset preset) async {
    await _readingPlanStore.start(preset);
  }

  Future<void> applyReciter(QuranAudioInfo reciter) async {
    if (reciter.kind != QuranAudioKind.recitation ||
        reciter.sourceId != arabicOriginalSourceId) {
      throw ArgumentError.value(
        reciter.id,
        'reciter',
        'Onboarding accepts only Arabic recitation audio.',
      );
    }
    await _settings.setSelectedAudioSource(arabicOriginalSourceId, reciter.id);
  }
}
