import 'package:flutter/foundation.dart';

import '../../../data/quran_audio_catalog.dart';
import '../../../data/translation_catalog.dart';
import '../../plans/reading_plan.dart';
import 'onboarding_controller.dart';
import 'onboarding_defaults.dart';
import 'onboarding_selection_applier.dart';

/// Coordinates first-run selections without owning any onboarding visuals.
///
/// The presentation layer can bind option taps to this controller while all
/// persistence continues to flow through [OnboardingSelectionApplier].
class OnboardingHostController extends ChangeNotifier {
  OnboardingHostController({
    required OnboardingSelectionApplier applier,
    OnboardingController? flow,
    String initialLanguageCode = 'en',
  }) : _applier = applier,
       flow = flow ?? OnboardingController(),
       _languageCode = initialLanguageCode.trim().toLowerCase() {
    _quranSourceId = onboardingDefaultQuranSourceForLanguage(_languageCode);
    _readingGoal = onboardingReadingPlanChoices.first;
    _reciter = onboardingReciterChoices.first;
  }

  final OnboardingSelectionApplier _applier;
  final OnboardingController flow;

  late String _languageCode;
  late String _quranSourceId;
  late ReadingPlanPreset _readingGoal;
  late QuranAudioInfo _reciter;
  bool _isApplying = false;

  String get languageCode => _languageCode;
  String get quranSourceId => _quranSourceId;
  ReadingPlanPreset get readingGoal => _readingGoal;
  QuranAudioInfo get reciter => _reciter;
  bool get isApplying => _isApplying;

  void selectLanguage(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty || code == _languageCode) return;
    _languageCode = code;
    _quranSourceId = onboardingDefaultQuranSourceForLanguage(code);
    notifyListeners();
  }

  void selectQuranSource(String sourceId) {
    final source = sourceId.trim();
    if (source.isEmpty || source == _quranSourceId) return;
    if (source != arabicOriginalSourceId) {
      final translation = translationById(source);
      if (translation == null || !translation.available) {
        throw ArgumentError.value(sourceId, 'sourceId', 'Unavailable Quran source.');
      }
    }
    _quranSourceId = source;
    notifyListeners();
  }

  void selectReadingGoal(ReadingPlanPreset preset) {
    if (preset == _readingGoal) return;
    _readingGoal = preset;
    notifyListeners();
  }

  void selectReciter(QuranAudioInfo reciter) {
    if (!onboardingReciterChoices.any((item) => item.id == reciter.id)) {
      throw ArgumentError.value(reciter.id, 'reciter', 'Unavailable reciter.');
    }
    if (reciter.id == _reciter.id) return;
    _reciter = reciter;
    notifyListeners();
  }

  Future<bool> applyCurrentAndNext() async {
    if (_isApplying) return false;
    _isApplying = true;
    notifyListeners();
    try {
      switch (flow.step) {
        case OnboardingStep.language:
          await _applier.applyLanguage(_languageCode);
        case OnboardingStep.translation:
          await _applier.applyQuranSource(_quranSourceId);
        case OnboardingStep.readingGoal:
          await _applier.applyReadingGoal(_readingGoal);
        case OnboardingStep.reciter:
          await _applier.applyReciter(_reciter);
      }
      return await flow.next();
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  void back() => flow.back();

  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }
}
