import 'onboarding_state.dart';

/// Resolves the app's first-run destination without coupling it to widgets.
///
/// Keeping this decision outside the presentation layer makes the startup gate
/// deterministic and easy to test before wiring the full onboarding host.
class OnboardingGate {
  OnboardingGate({Future<bool> Function()? isCompleted})
      : _isCompleted = isCompleted ?? OnboardingState.isCompleted;

  final Future<bool> Function() _isCompleted;

  Future<bool> shouldShowOnboarding() async => !(await _isCompleted());
}
