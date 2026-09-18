import 'package:flutter/material.dart';

import '../application/onboarding_gate.dart';

/// Resolves the persisted first-run decision before choosing the app's root.
///
/// The gate owns no onboarding choices or styling. It only keeps [AppShell]
/// from flashing before the persisted onboarding state has been resolved.
class OnboardingStartupGate extends StatefulWidget {
  const OnboardingStartupGate({
    required this.onboarding,
    required this.app,
    super.key,
    this.gate,
    this.loading = const SizedBox.shrink(),
  });

  final Widget onboarding;
  final Widget app;
  final OnboardingGate? gate;
  final Widget loading;

  @override
  State<OnboardingStartupGate> createState() => _OnboardingStartupGateState();
}

class _OnboardingStartupGateState extends State<OnboardingStartupGate> {
  late Future<bool> _shouldShowOnboarding;

  @override
  void initState() {
    super.initState();
    _shouldShowOnboarding =
        (widget.gate ?? OnboardingGate()).shouldShowOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowOnboarding,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return widget.loading;
        return snapshot.data! ? widget.onboarding : widget.app;
      },
    );
  }
}
