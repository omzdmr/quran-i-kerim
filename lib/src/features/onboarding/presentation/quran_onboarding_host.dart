import 'package:flutter/material.dart';

import '../../../data/translation_catalog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_defaults.dart';
import '../application/onboarding_host_controller.dart';
import 'quran_onboarding_visual_flow.dart';

/// Binds the existing onboarding presentation to the persisted selection flow.
///
/// Root/startup gating intentionally stays outside this widget so first-run
/// routing can be enabled and tested as a separate change.
class QuranOnboardingHost extends StatelessWidget {
  const QuranOnboardingHost({
    required this.controller,
    required this.onCompleted,
    super.key,
  });

  final OnboardingHostController controller;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, controller.flow]),
      builder: (context, _) => _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final generated = GeneratedAppLocalizations.of(context)!;
    final flow = controller.flow;
    final isBusy = controller.isApplying || flow.isCompleting;

    final (title, options, selectedId, onSelected) = switch (flow.step) {
      OnboardingStep.language => (
        generated.onboardingLanguageTitle,
        const <QuranOnboardingOption>[
          QuranOnboardingOption(
            id: 'tr',
            title: 'Türkçe',
            subtitle: 'TR',
            icon: Icons.language_rounded,
          ),
          QuranOnboardingOption(
            id: 'en',
            title: 'English',
            subtitle: 'EN',
            icon: Icons.language_rounded,
          ),
          QuranOnboardingOption(
            id: 'ar',
            title: 'العربية',
            subtitle: 'AR',
            icon: Icons.language_rounded,
          ),
          QuranOnboardingOption(
            id: 'az',
            title: 'Azərbaycanca',
            subtitle: 'AZ',
            icon: Icons.language_rounded,
          ),
          QuranOnboardingOption(
            id: 'ru',
            title: 'Русский',
            subtitle: 'RU',
            icon: Icons.language_rounded,
          ),
        ],
        controller.languageCode,
        controller.selectLanguage,
      ),
      OnboardingStep.translation => (
        generated.onboardingTranslationTitle,
        _translationOptions(controller.languageCode),
        controller.quranSourceId,
        controller.selectQuranSource,
      ),
      OnboardingStep.readingGoal => (
        generated.onboardingReadingGoalTitle,
        onboardingReadingPlanChoices
            .map(
              (preset) => QuranOnboardingOption(
                id: preset.id,
                title: l10n.text(preset.titleKey),
                subtitle: l10n.text(preset.durationKey),
                icon: Icons.calendar_month_rounded,
              ),
            )
            .toList(growable: false),
        controller.readingGoal.id,
        (String id) {
          final preset = onboardingReadingPlanChoices.firstWhere(
            (item) => item.id == id,
          );
          controller.selectReadingGoal(preset);
        },
      ),
      OnboardingStep.reciter => (
        generated.onboardingReciterTitle,
        onboardingReciterChoices
            .map(
              (reciter) => QuranOnboardingOption(
                id: reciter.id,
                title: reciter.title,
                subtitle: reciter.attribution,
                icon: Icons.headphones_rounded,
              ),
            )
            .toList(growable: false),
        controller.reciter.id,
        (String id) {
          final reciter = onboardingReciterChoices.firstWhere(
            (item) => item.id == id,
          );
          controller.selectReciter(reciter);
        },
      ),
    };

    return QuranOnboardingVisualFlow(
      progress: flow.progress,
      title: title,
      options: options,
      selectedId: selectedId,
      onSelected: isBusy ? (_) {} : onSelected,
      primaryLabel: flow.isLastStep
          ? generated.onboardingFinish
          : generated.onboardingContinue,
      onPrimary: isBusy
          ? null
          : () async {
              final completed = await controller.applyCurrentAndNext();
              if (completed) onCompleted();
            },
      secondaryLabel: flow.canGoBack ? generated.onboardingBack : null,
      onSecondary: flow.canGoBack && !isBusy ? controller.back : null,
    );
  }

  List<QuranOnboardingOption> _translationOptions(String languageCode) {
    final language = languageCode.trim().toLowerCase();
    if (language == 'ar') {
      return const <QuranOnboardingOption>[
        QuranOnboardingOption(
          id: arabicOriginalSourceId,
          title: 'القرآن الكريم',
          subtitle: 'العربية',
          icon: Icons.menu_book_rounded,
        ),
      ];
    }

    return translationCatalog
        .where(
          (translation) =>
              translation.available && translation.languageCode == language,
        )
        .map(
          (translation) => QuranOnboardingOption(
            id: translation.id,
            title: translation.name,
            subtitle: translation.publisher,
            icon: Icons.translate_rounded,
          ),
        )
        .toList(growable: false);
  }
}
