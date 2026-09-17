import 'package:shared_preferences/shared_preferences.dart';

/// Local-first persistence for the app's first-run onboarding gate.
///
/// Presentation and individual onboarding choices remain separate concerns.
/// This state only answers whether the first-run flow has been completed.
class OnboardingState {
  OnboardingState._();

  static const completionKey = 'onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completionKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completionKey, true);
  }
}
