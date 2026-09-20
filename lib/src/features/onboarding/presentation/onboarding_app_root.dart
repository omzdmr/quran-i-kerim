import 'package:flutter/material.dart';

import '../../../settings/app_settings.dart';
import '../../../shell/app_shell.dart';
import '../application/onboarding_host_controller.dart';
import '../application/onboarding_selection_applier.dart';
import 'onboarding_startup_gate.dart';
import 'quran_onboarding_host.dart';

/// Owns the first-run onboarding controller and switches to the normal app
/// shell as soon as onboarding completes.
class OnboardingAppRoot extends StatefulWidget {
  const OnboardingAppRoot({required this.settings, super.key});

  final AppSettings settings;

  @override
  State<OnboardingAppRoot> createState() => _OnboardingAppRootState();
}

class _OnboardingAppRootState extends State<OnboardingAppRoot> {
  late final OnboardingHostController _controller;
  bool _completedInSession = false;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingHostController(
      applier: OnboardingSelectionApplier(settings: widget.settings),
      initialLanguageCode: widget.settings.locale?.languageCode ?? 'en',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completedInSession) return const AppShell();

    return OnboardingStartupGate(
      onboarding: QuranOnboardingHost(
        controller: _controller,
        onCompleted: () {
          if (!mounted) return;
          setState(() => _completedInSession = true);
        },
      ),
      app: const AppShell(),
    );
  }
}
