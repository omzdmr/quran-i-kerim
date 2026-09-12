import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/generated_app_localizations.dart';
import '../learn/presentation/memorization_overview.dart';

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
            0 => const _LessonsOverview(key: ValueKey('lessons')),
            1 => const MemorizationOverview(key: ValueKey('memorize')),
            _ => const _ArticlesOverview(key: ValueKey('articles')),
          },
        ),
      ],
    );
  }
}

class _LessonsOverview extends StatelessWidget {
  const _LessonsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final steps = <({IconData icon, String label})>[
      (icon: Icons.menu_book_outlined, label: l10n.quranLearnFlowVerse),
      (icon: Icons.translate_rounded, label: l10n.quranLearnFlowMeaning),
      (icon: Icons.fact_check_outlined, label: l10n.quranLearnFlowSource),
      (icon: Icons.quiz_outlined, label: l10n.quranLearnFlowReview),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.quranLearnFlowTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.quranLearnFlowBody,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < steps.length; index++) ...[
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(steps[index].icon, color: scheme.primary),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        steps[index].label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (index != steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      height: 16,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EmptyStateCard(
          icon: Icons.verified_outlined,
          title: l10n.quranLearnLessons,
          body: l10n.quranLearnLessonsEmpty,
        ),
      ],
    );
  }
}

class _ArticlesOverview extends StatelessWidget {
  const _ArticlesOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    return _EmptyStateCard(
      icon: Icons.article_outlined,
      title: l10n.quranLearnArticlesEmptyTitle,
      body: l10n.quranLearnArticlesEmptyBody,
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF315348), Color(0xFF182B25)],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
