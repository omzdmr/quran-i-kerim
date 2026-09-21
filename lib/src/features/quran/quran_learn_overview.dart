import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/generated_app_localizations.dart';
import '../learn/presentation/learn_lessons_overview.dart';
import '../learn/presentation/learn_reference_overview.dart';
import '../learn/presentation/memorization_overview.dart';
import '../learn/presentation/memorization_review_coverage_screen.dart';

class QuranLearnOverview extends StatefulWidget {
  const QuranLearnOverview({super.key});

  @override
  State<QuranLearnOverview> createState() => _QuranLearnOverviewState();
}

class _QuranLearnOverviewState extends State<QuranLearnOverview> {
  int _tab = 0;

  void _select(int index) {
    if (_tab == index) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = index);
  }

  Future<void> _openReviewCoverage() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MemorizationReviewCoverageScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _FeatureHero(
          icon: Icons.lightbulb_outline_rounded,
          title: l10n.quranLearnTitle,
          body: l10n.quranLearnBody,
        ),
        const SizedBox(height: 16),
        _LearnSwitcher(
          selectedIndex: _tab,
          labels: [
            l10n.quranLearnLessons,
            l10n.quranLearnMemorize,
            l10n.quranLearnArticles,
          ],
          onSelected: _select,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: switch (_tab) {
            0 => const LearnLessonsOverview(key: ValueKey('lessons')),
            1 => Column(
                key: const ValueKey('memorize'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    label: l10n.memorizeTodayReview,
                    child: OutlinedButton.icon(
                      onPressed: _openReviewCoverage,
                      icon: const Icon(Icons.history_toggle_off_rounded),
                      label: Text(l10n.memorizeTodayReview),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const MemorizationOverview(),
                ],
              ),
            _ => const LearnReferenceOverview(key: ValueKey('articles')),
          },
        ),
      ],
    );
  }
}

class _LearnSwitcher extends StatelessWidget {
  const _LearnSwitcher({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _FeatureHero extends StatelessWidget {
  const _FeatureHero({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF315348),
            Color(0xFF183A31),
            Color(0xFF453B5A),
          ],
          stops: [0, .62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25C58A).withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF25C58A).withValues(alpha: .58),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 38),
                ),
                const Positioned(
                  top: 8,
                  right: 13,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF5CE7B3),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
