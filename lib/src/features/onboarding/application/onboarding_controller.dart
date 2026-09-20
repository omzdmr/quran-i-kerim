import 'package:flutter/foundation.dart';

import 'onboarding_state.dart';

enum OnboardingStep { language, translation, readingGoal, reciter }

/// Owns first-run step navigation without coupling onboarding to its visuals.
///
/// Individual choices are applied by the presentation/host layer through the
/// existing settings and catalogue APIs. This controller only keeps the flow
/// bounded and persists completion after the final step.
class OnboardingController extends ChangeNotifier {
  OnboardingController({
    Future<void> Function()? markCompleted,
  }) : _markCompleted = markCompleted ?? OnboardingState.markCompleted;

  final Future<void> Function() _markCompleted;
  int _index = 0;
  bool _isCompleting = false;

  OnboardingStep get step => OnboardingStep.values[_index];
  int get stepIndex => _index;
  int get stepCount => OnboardingStep.values.length;
  double get progress => (_index + 1) / stepCount;
  bool get canGoBack => _index > 0;
  bool get isLastStep => _index == stepCount - 1;
  bool get isCompleting => _isCompleting;

  void back() {
    if (!canGoBack || _isCompleting) return;
    _index -= 1;
    notifyListeners();
  }

  Future<bool> next() async {
    if (_isCompleting) return false;
    if (!isLastStep) {
      _index += 1;
      notifyListeners();
      return false;
    }

    _isCompleting = true;
    notifyListeners();
    try {
      await _markCompleted();
      return true;
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }
}
