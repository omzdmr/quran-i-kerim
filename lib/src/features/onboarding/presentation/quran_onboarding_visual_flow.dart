import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuranOnboardingOption {
  const QuranOnboardingOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.preview,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? preview;
}

/// Reference-inspired onboarding surface.
///
/// This widget intentionally owns presentation only. Persistence, translation
/// catalogue binding, Arabic font installation and audio downloads stay in the
/// feature/controller layer so the same UI can be reused on Android and iOS.
class QuranOnboardingVisualFlow extends StatelessWidget {
  const QuranOnboardingVisualFlow({
    required this.progress,
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
    this.subtitle,
    this.preview,
    this.secondaryLabel,
    this.onSecondary,
    this.leading,
  });

  final double progress;
  final String title;
  final String? subtitle;
  final Widget? preview;
  final List<QuranOnboardingOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF073F39), Color(0xFF062F2B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          color: const Color(0xFF16C784),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (preview != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: preview!,
                      ),
                    ],
                    const SizedBox(height: 22),
                    for (final option in options) ...[
                      _OnboardingChoiceCard(
                        option: option,
                        selected: option.id == selectedId,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(option.id);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B971),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onSecondary,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(secondaryLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingChoiceCard extends StatelessWidget {
  const _OnboardingChoiceCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final QuranOnboardingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: .11)
          : Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.white70 : Colors.white12,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(option.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (option.preview != null) ...[
                      const SizedBox(height: 10),
                      option.preview!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 130),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: Color(0xFF25D58B),
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('idle'),
                        color: Colors.white38,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
