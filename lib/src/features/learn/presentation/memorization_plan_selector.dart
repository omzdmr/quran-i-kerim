import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/memorization_plan_engine.dart';

class MemorizationPlanChoiceCopy {
  const MemorizationPlanChoiceCopy({
    required this.pace,
    required this.title,
    required this.subtitle,
    required this.weeklyLoadLabel,
    required this.durationLabel,
  });

  final MemorizationPlanPace pace;
  final String title;
  final String subtitle;
  final String weeklyLoadLabel;
  final String durationLabel;
}

class MemorizationPlanSelectorLabels {
  const MemorizationPlanSelectorLabels({
    required this.title,
    required this.body,
    required this.newLabel,
    required this.recentLabel,
    required this.oldLabel,
    required this.consolidationLabel,
    required this.continueLabel,
  });

  final String title;
  final String body;
  final String newLabel;
  final String recentLabel;
  final String oldLabel;
  final String consolidationLabel;
  final String continueLabel;
}

/// Visual selector for the research-backed hifz plan presets.
///
/// Persistence and daily queue generation belong to the application layer.
class MemorizationPlanSelector extends StatelessWidget {
  const MemorizationPlanSelector({
    required this.labels,
    required this.choices,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
    super.key,
  });

  final MemorizationPlanSelectorLabels labels;
  final List<MemorizationPlanChoiceCopy> choices;
  final MemorizationPlanPace selected;
  final ValueChanged<MemorizationPlanPace> onSelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labels.title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          labels.body,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _MethodStrip(labels: labels),
        const SizedBox(height: 18),
        for (final choice in choices) ...[
          _PlanCard(
            choice: choice,
            selected: choice.pace == selected,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(choice.pace);
            },
          ),
          const SizedBox(height: 11),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            labels.continueLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _MethodStrip extends StatelessWidget {
  const _MethodStrip({required this.labels});

  final MemorizationPlanSelectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _MethodStep(index: '1', label: labels.newLabel)),
              const SizedBox(width: 8),
              Expanded(child: _MethodStep(index: '2', label: labels.recentLabel)),
              const SizedBox(width: 8),
              Expanded(child: _MethodStep(index: '3', label: labels.oldLabel)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_repeat_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labels.consolidationLabel,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodStep extends StatelessWidget {
  const _MethodStep({required this.index, required this.label});

  final String index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            index,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final MemorizationPlanChoiceCopy choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: .13)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  selected ? Icons.route_rounded : Icons.calendar_month_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            choice.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          choice.durationLabel,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      choice.weeklyLoadLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
